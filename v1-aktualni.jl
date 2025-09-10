using GLMakie
using Random
using OffsetArrays

# const g_size = 10
# const CELL_SIZE = 40  # pixels per cell
# const GRID_PIXELS = g_size * CELL_SIZE

mutable struct Board
    board::AbstractMatrix{Bool}
    new_board::AbstractMatrix{Bool}
    g_size::Int
    CELL_SIZE::Int
    GRID_PIXELS::Int
end

function new_board(g_size::Int)
    A = OffsetArray(rand(Bool, g_size + 2, g_size + 2), 0:g_size + 1, 0:g_size + 1)
end

function initialize()   
    return Board(
        OffsetArray(rand(Bool, 10 + 2, 10 + 2), 0:(10 + 1), 0:(10 + 1)), #board
        OffsetArray(rand(Bool, 10 + 2, 10 + 2), 0:(10 + 1), 0:(10 + 1)), # new_board)
        10, # g_size
        40, # CELL_SIZE
        400 # GRID_PIXELS (g_size * CELL_SIZE)
        )
end

function wrap_board(board::AbstractMatrix{Bool}, g_size::Int)
    # g = g_size # g_size + 2

    # edges
    board[0,    1:g_size] .= board[g_size, 1:g_size]    # top halo
    board[g_size+1,  1:g_size] .= board[1, 1:g_size]    # bottom halo
    board[1:g_size,  0]   .= board[1:g_size, g_size]    # left halo
    board[1:g_size, g_size+1]  .= board[1:g_size, 1]    # right halo

    # corners
    board[0,    0]   = board[g_size, g_size]  # top-left corner
    board[0,    g_size+1] = board[g_size, 1]  # top-right corner
    board[g_size+1,  0]   = board[1, g_size]  # bottom-left corner
    board[g_size+1, g_size+1]  = board[1, 1]  # bottom-right corner
end

function print_board(b::Matrix{Bool})
    println("Next")
    for row in axes(b, 1) # misto 1:size, hodi mi zrovna zacatek:konec
        for col in axes(b, 2)
            print(b[row, col] ? "■ " : "∙ ")
        end
        println()  # New line after each row
    end
end

function next_generation!(b::Board)
    
    for i in 1:b.g_size, j in 1:b.g_size
        neighbors = sum(b.board[i-1:i+1, j-1:j+1]) - b.board[i, j]

        if neighbors == 3 || (b.board[i, j] && neighbors == 2)
            b.new_board[i, j] = true
        elseif b.board[i, j] && (neighbors < 2 || neighbors > 3) 
            b.new_board[i, j] = false
        else
            b.new_board[i, j] = false
        end
    end

    b.board, b.new_board = b.new_board, b.board # bez copy mi to jenom odkazuje na misto v pameti ale new_board, a to potom upravuju, takze tam bude delat bordel
end

function make_figure(b::Board)

    # ? je lepsi mit promenne soucasti structu nebo funkce, kdyz je nidke mimo nepouzivam?
    target = 0
    stop_count = 0
    delay_plot = 2.0
    gens_plot = 5
    last_update = 0.0
    
    isrunning_plot = Observable(false) 
    current_gen_plot = Observable(0) # ve fig, pocitani generaci
    board_plot = Observable(rand(Bool, b.g_size, b.g_size))
    
    board_plot[] .= b.board[1:b.g_size, 1:b.g_size]
    
    fig = Figure(size = (b.GRID_PIXELS + 200, b.GRID_PIXELS + 400))
    gl = GridLayout(fig[1, 1], alignmode = Outside())
    ax = Axis(gl[1, 1], 
    aspect = DataAspect(),
    title = "Game of Life (10×10)",
    xticklabelsvisible = false, yticklabelsvisible = false,
    xticksvisible = false, yticksvisible = false)
        
    colsize!(gl, 1, Fixed(b.GRID_PIXELS))
    rowsize!(gl, 1, Fixed(b.GRID_PIXELS))
    
    hm = heatmap!(ax, board_plot, colormap = [:black, :white], colorrange = (0, 1))
    
    gen_label = Label(fig[1, 2], lift(n -> "Generation No.: $n", current_gen_plot))
    slider_frame = GridLayout(fig[2, 1])
    
    delay_slider = Slider(slider_frame[1, 1], range=0.1:0.1:5.0, startvalue=2.0)
    gens_slider = Slider(slider_frame[1, 2], range=1:50, startvalue=5)
    
    delay_label = Label(slider_frame[2, 1], lift(x -> "Speed: $x", delay_slider.value))
    gens_label = Label(slider_frame[2, 2], lift(x -> "Generations: $x", gens_slider.value))
    
    run_button = Button(fig[3, 1], label = lift(x -> x ? "Stop" : "Run", isrunning_plot)) # if x = true -> "Stop"
    reset_button = Button(fig[4, 1], label="Reset")
    
    on(delay_slider.value) do value
        delay_plot = value
    end
    
    on(gens_slider.value) do value
        gens_plot = value
    end
    
    on(run_button.clicks) do _
        isrunning_plot[] = !isrunning_plot[]
        if isrunning_plot[]
            target = gens_plot + stop_count
        end
    end
    
    on(fig.scene.events.tick) do _
        isrunning_plot[] || return # if not running, do nothing
        
        now = time()
        if (current_gen_plot[] < target) && (now - last_update >= delay_plot)            
            wrap_board(b.board, b.g_size)  
            next_generation!(b)
            current_gen_plot[] += 1
            
            if current_gen_plot[] != 0 && (current_gen_plot[] % target == 0)
                stop_count += gens_plot  # reset generation count when reaching target
                isrunning_plot[] = false
            end
            board_plot[] = b.board[1:b.g_size, 1:b.g_size]
            last_update = now
            print_board(board_plot[])
        end
        # ? je jiny zpusob jak kontrolovat rychlost, tick.delta_time asi menit nemuzu?, FPS asi menit nemuzu, pokud nepouzivam record?
        #sleep(delay_plot)  
    end

    on(reset_button.clicks) do _
    
        isrunning_plot[] = false
        b.board = new_board(b.g_size)
        board_plot[] = b.board[1:b.g_size, 1:b.g_size]

        current_gen_plot[] = 0
        stop_count = 0
    end
    
    on(ax.scene.events.mousebutton) do buttons
    if buttons.button == Mouse.left && buttons.action == Mouse.press
        pos = mouseposition(ax)
        i, j = floor.(Int, pos) # rounding to Int
        if 1 ≤ i ≤ b.g_size && 1 ≤ j ≤ b.g_size
            b.board[i, j] = !b.board[i, j]
            board_plot[] = b.board[1:b.g_size, 1:b.g_size]
        end
    end
    end

    display(fig)
end

init = initialize()
make_figure(init)
# step buttonek
# TODO upravit mouse aby fungovala idelane ve stredu ne v pravem hronim rohu