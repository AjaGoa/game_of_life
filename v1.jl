using GLMakie
using Random
using OffsetArrays

#TODO reading: 
# https://docs.julialang.org/en/v1/manual/performance-tips/index.html#General-advice
# ruzne druhy konstruktoru: https://docs.julialang.org/en/v1/manual/constructors/
# https://www.geeksforgeeks.org/dsa/stack-vs-heap-memory-allocation/

const DEFAULT_FRAMERATE = 15.0

GLMakie.activate!(framerate = DEFAULT_FRAMERATE)

mutable struct Board
    _board::OffsetArray{Bool, 2}
    _new_board::OffsetArray{Bool, 2}
    board::SubArray{Bool, 2}  # vyborne takze to nebylo v SubArray - ? asi nesedel typ nekde pozdeji ale proc pomohla zmena na obecnejsi
end

function Board(x::Int, y::Int)
    _board = OffsetArray(rand(Bool, x + 2, y + 2), 0:x + 1, 0:y + 1)
    _new_board = similar(_board)
    board = @view _board[1:x, 1:y]
    Board(_board, _new_board, board)
end

# getproperty

function reset!(b::Board)
    x, y = size(b._board)
    #? b._board .= rand(Bool) <- nejde protoze broadcastuje jenom jednu random hodnotu 
    new_data = OffsetArray(rand(Bool, x, y), axes(b._board)) # urcite existuje neco lepsiho, urcite muzu zamichat jenom viditelnou cast, zbytek stejne kopiruju, ale to by se mi zas neprepsalo do vypoctu 
    b._board .= new_data
    b.board .= @view b._board[1:x-2, 1:y-2] # bez @view zlobi spusteni po clear/resetu
    # taky bych to mohla zrovna posunout do data[], ale otazka jestli by to pak nebylo zpatenejsi
end 

function clear!(b::Board)
    x, y = size(b._board) .- 2
    b._board .= false
    b.board .= @view b._board[1:x, 1:y]
end

# OM: to by mohla byt proste `Figure`, nebo `GameOfLifeFigure` nebo tak neco, viz dal
mutable struct FigureParams
    isrunning::Observable{Bool}
    current_gen::Observable{Int} # ve fig, pocitani generaci
    # OM: trochu pedantsky, ale tohle je vlastnost simulace, takze nesouvisi primo s figurkou. ale cely je to dost jednoduchy na to, aby to nevadilo
    # OM: naopak bych tady mozna pridal tu samotnou figure, at je to proste celky prohromade. ten `make_figure` by pak mohl bejt konstruktor
end
# OM
# Dalsi moznost je, ze na to zadnou strukturu delat nebudu, vyrobim jenom Makie Figure a vsechno delam pres ni, ono je to tam schovany.
# Ale tohle je docela cisty a pohodlny, ulozim si k primimu pristupu par veci, co se mi hodi.

function FigureParams()
    isrunning = Observable(false)
    current_gen = Observable(0)

    return FigureParams(isrunning, current_gen) #board_plot)
end

function wrap_board!(board::OffsetArray{Bool})
    x = last(axes(board, 1)) - 1  # rows - da mi posledni (posunuty) index z OffsetArray 
    y = last(axes(board, 2)) - 1  # cols

    # OM
    # - Tady je dopad na vykon zanedbatelny, ale chapat views je dulezite.
    # - K diskuzi - pouziti spawn.
    # edges
    # @views - pro blok, @view pro jeden vyraz
    @views begin
        board[0  , 1:y] .= board[x  , 1:y]   # top halo
        board[x+1, 1:y] .= board[1  , 1:y]   # bottom halo
        board[1:x,   0] .= board[1:x,   y]   # left halo
        board[1:x, y+1] .= board[1:x,   1]   # right halo
    end

    # corners
    begin
        board[0  ,   0] = board[x, y]   # top-left corner
        board[0  , y+1] = board[x, 1]   # top-right corner
        board[x+1,   0] = board[1, y]   # bottom-left corner
        board[x+1, y+1] = board[1, 1]   # bottom-right corner
    end
end

function print_board(b::OffsetArray{Bool})
    println("Next")
    for row in axes(b, 1) # misto 1:size, hodi mi zrovna zacatek:konec # print i s halo
        for col in axes(b, 2)
            print(b[row, col] ? "■ " : "∙ ")
        end
        println()  # New line after each row
    end
end

function next_generation!(b::Board)
    x, y = size(b.board)

    wrap_board!(b._board)
    for i in 1:x, j in 1:y
        neighbors = sum(b._board[i-1:i+1, j-1:j+1]) - b._board[i, j]
        b._new_board[i, j] = (neighbors == 3 || (b._board[i, j] && neighbors == 2))
    end
    b._board, b._new_board = b._new_board, b._board # bez copy mi to jenom odkazuje na misto v pameti ale new_board, a to potom upravuju, takze tam bude delat bordel
end

toggle_running!(fp::FigureParams) = fp.isrunning[] = !fp.isrunning[]

function make_figure(b::Board, fp::FigureParams)
    x, y = size(b.board)

    fig = Figure(size = (700, 700)) # lepsi pouzit dynamickou velikost cells
    gl = GridLayout(fig[1, 1], alignmode = Outside())
    ax = Axis(gl[1, 1], # span (1.0, 10.0) , here set up automatically based on the data I put in (board_plot), but can be set manually
        aspect = DataAspect(),
        title = "Game of Life",
        xticklabelsvisible = false, yticklabelsvisible = false,
        xticksvisible = false, yticksvisible = false)
    colsize!(gl, 1, Fixed(400)) 
    rowsize!(gl, 1, Fixed(400))
    empty!(ax.interactions)

    data = Observable(@view b.board[1:x, 1:y])
    hm = heatmap!(ax, data, colormap = [:black, :white], colorrange = (0, 1))

    gen_label = Label(fig[2, 1], lift(n -> "Generation No.: $n", fp.current_gen))

    run_button = Button(fig[3, 1], label = lift(x -> x ? "Stop" : "Run", fp.isrunning)) # if x = true -> "Stop"
    reset_button = Button(fig[4, 1], label="Reset")
    clear_button = Button(fig[5, 1], label="Clear")

    on(run_button.clicks) do _
        toggle_running!(fp)
    end

    on(ax.scene.events.keyboardbutton) do event
        if event.action == Keyboard.press && event.key == Keyboard.space
            toggle_running!(fp)
        end
    end
    # nesel by ten button a keyboard sloucit do jednoho eventu ?
    # OM: To ne, jsou to dva ruzny triggery. Pokud je ale opakovanej kod v tom callbacku, muzu ho vytahnout do funkce, kterou pak volam z tech vic mist.

    on(fig.scene.events.tick) do _
        fp.isrunning[] || return # if not running, do nothing

        next_generation!(b)
        fp.current_gen[] += 1
        data[] = @view b.board[1:x, 1:y] # nebo data[] .= b.board[1:x, 1:y]
        # OM: view je myslim lepsi, ale urcite to neni nutny. taky by se teda nemusel porad vytvaret, muzeme si ho ulozit
        #print_board(fp.board_plot[])
    end

    on(reset_button.clicks) do _
        fp.isrunning[] = false
        reset!(b)
        data[] = @view b.board[1:x, 1:y]
        fp.current_gen[] = 0
    end

    on(clear_button.clicks) do _
        fp.isrunning[] = false
        clear!(b) # proc se mi ta cista zobrazi az potom co spustim dalsi generaci ? (pokud zrovna neupdatuju do b.board)         
        fp.current_gen[] = 0
        data[] = @view b.board[1:x, 1:y] # nemelo by mi to tady zrovna triggnout ten plot do heatmap ?
    end

    on(ax.scene.events.mousebutton) do buttons
        #https://docs.makie.org/dev/explanations/events?utm_source=chatgpt.com#Mouse-Interaction

        if buttons.button == Mouse.left && buttons.action == Mouse.press
            pos = mouseposition(ax) # cursor position in axis units (not the full window)
            i, j = round.(Int, pos) # rounding to Int
            # OM: hezky pouziti Unicode :-)
            if 1 ≤ i ≤ x && 1 ≤ j ≤ y
                b.board[i, j] = !b.board[i, j]
                data[] = @view b.board[1:x, 1:y]
            end
        end
    end
    display(fig)
    # OM: myslim nemusi byt 
end

function main()
    b = Board(50, 50)
    fp = FigureParams()
    make_figure(b, fp)
end

# OM: main je normalne bez argumentu, tohle by byl spis nejakej `run`, co se z toho main (nebo treba interaktivne z REPLu) zavola
main()  