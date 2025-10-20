using GLMakie
using Random
using OffsetArrays

GLMakie.activate!(framerate = 15.0) 

mutable struct Board
    board::OffsetMatrix{Bool} # AbstractMatrix je "nadrazena" Matrix/OffsetM/... 
    new_board::OffsetMatrix{Bool}
end

# ruzne druhy konstruktoru: https://docs.julialang.org/en/v1/manual/constructors/ 
mutable struct FigureParams
    isrunning::Observable{Bool} 
    current_gen::Observable{Int} # ve fig, pocitani generaci
    board_plot::Observable{Matrix{Bool}}
end

function Board_init(x::Int, y::Int) # viditelne
    board = OffsetArray(rand(Bool, x + 2, y + 2), 0:x + 1, 0:y + 1)
    new_board = similar(board)
    return Board(board, new_board)
end

function FigureParams(b::Board)
    x, y = size(b.board) .- 2

    isrunning = Observable(false)
    current_gen = Observable(0)
    board_plot = Observable(b.board[1:x, 1:y])

    return FigureParams(isrunning, current_gen, board_plot)
end

function wrap_board!(board::OffsetMatrix{Bool})
    x, y = size(board) .- 2# x = row, y = col 

    # edges
    board[0,    1:y] .= board[x, 1:y]    # top halo
    board[(x + 1),  1:y] .= board[1, 1:y]    # bottom halo
    board[1:x,  0]   .= board[1:x, y]    # left halo
    board[1:x, (y + 1)]  .= board[1:x, 1]    # right halo

    # corners
    board[0,    0]   = board[x, y]  # top-left corner
    board[0, (y + 1)] = board[x, 1]  # top-right corner
    board[(x + 1),  0]   = board[1, y]  # bottom-left corner
    board[(x + 1), (y + 1)]  = board[1, 1]  # bottom-right corner
end

function print_board(b::OffsetMatrix{Bool})
    println("Next")
    for row in axes(b, 1) # misto 1:size, hodi mi zrovna zacatek:konec # print i s halo
        for col in axes(b, 2)
            print(b[row, col] ? "■ " : "∙ ")
        end
        println()  # New line after each row
    end
end

function next_generation!(b::Board)
    x, y = size(b.board) .- 2

    wrap_board!(b.board)
    for i in 1:x, j in 1:y
        neighbors = sum(b.board[i-1:i+1, j-1:j+1]) - b.board[i, j]
        b.new_board[i, j] = (neighbors == 3 || (b.board[i, j] && neighbors == 2))
    end
    b.board, b.new_board = b.new_board, b.board # bez copy mi to jenom odkazuje na misto v pameti ale new_board, a to potom upravuju, takze tam bude delat bordel
end

function make_figure(b::Board, fp::FigureParams)
    x, y = size(b.board) .- 2
    
    fig = Figure(size = (700, 700)) # ! # lepsi pouzit dynamickou velikost cells
    gl = GridLayout(fig[1, 1], alignmode = Outside())
    ax = Axis(gl[1, 1], # span (1.0, 10.0) , here set up automatically based on the data I put in (board_plot), but can be set manually
        aspect = DataAspect(),
        title = "Game of Life",
        xticklabelsvisible = false, yticklabelsvisible = false,
        xticksvisible = false, yticksvisible = false)
    colsize!(gl, 1, Fixed(400)) 
    rowsize!(gl, 1, Fixed(400))
    empty!(ax.interactions) # disable default interactions
    
    hm = heatmap!(ax, fp.board_plot, colormap = [:black, :white], colorrange = (0, 1))
    
    gen_label = Label(fig[2, 1], lift(n -> "Generation No.: $n", fp.current_gen))
    
    run_button = Button(fig[3, 1], label = lift(x -> x ? "Stop" : "Run", fp.isrunning)) # if x = true -> "Stop"
    reset_button = Button(fig[4, 1], label="Reset")
    clear_button = Button(fig[5, 1], label="Clear")
    
    on(run_button.clicks) do _
        fp.isrunning[] = !fp.isrunning[]
    end

    on(ax.scene.events.keyboardbutton) do event
        if event.action == Keyboard.press && event.key == Keyboard.space
            fp.isrunning[] = !fp.isrunning[]
        end
    end
    # nesel by ten button a keyboard sloucit do jednoho eventu ?
    on(fig.scene.events.tick) do _
        fp.isrunning[] || return # if not running, do nothing

        next_generation!(b)
        fp.current_gen[] += 1            
        fp.board_plot[] = b.board[1:x, 1:y] # nemuze byt .= aby heatmap zaznamenal zmenu
        
        #print_board(fp.board_plot[])  
    end

    on(reset_button.clicks) do _
        fp.isrunning[] = false
        b.board = OffsetArray(rand(Bool, x + 2, y + 2), 0:x + 1, 0:y + 1)
        fp.board_plot[] = b.board[1:x, 1:y]
        fp.current_gen[] = 0
    end
    
    on(clear_button.clicks) do _
        fp.isrunning[] = false
        b.board = OffsetArray(falses(x + 2, y + 2), 0:x + 1, 0:y + 1)
        fp.board_plot[] = b.board[1:x, 1:y]
        fp.current_gen[] = 0
    end

    on(ax.scene.events.mousebutton) do buttons
        #https://docs.makie.org/dev/explanations/events?utm_source=chatgpt.com#Mouse-Interaction

        if buttons.button == Mouse.left && buttons.action == Mouse.press
            pos = mouseposition(ax) # cursor position in axis units (not the full window)
            i, j = round.(Int, pos) # rounding to Int
            if 1 ≤ i ≤ x && 1 ≤ j ≤ y
                b.board[i, j] = !b.board[i, j]
                fp.board_plot[] = b.board[1:x, 1:y]
            end
        end
    end
    display(fig)
end

function main(x, y)
    b = Board_init(x, y)
    fp = FigureParams(b)
    make_figure(b, fp)
end

main(50, 50)