using GLMakie
using Random
using OffsetArrays

const g_size = 10
const CELL_SIZE = 40  # pixels per cell
const GRID_PIXELS = g_size * CELL_SIZE

mutable struct Board
    board::Matrix{Bool}
    new_board::Matrix{Bool}
end

function new_board()
    A = rand(Bool, g_size, g_size)
end

function initialize()   
    return Board(
        new_board(), #board
        new_board() # new_board
        )
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
    g = size(b.board, 1)

    for i in 1:g, j in 1:g
        neighbors = 0
        for di in -1:1, dj in -1:1
            if di != 0 || dj != 0 # vynechani [i, j]
                ni = mod1(i + di, g)  # row
                nj = mod1(j + dj, g)  # col
                neighbors += b.board[ni, nj]
            end
        end

        if neighbors == 3 || (b.board[i, j] && neighbors == 2)
             b.new_board[i, j] = true
         elseif b.board[i, j] && (neighbors < 2 || neighbors > 3) 
             b.new_board[i, j] = false
         else
             b.new_board[i, j] = false
         end
    end

    b.board, b.new_board = b.new_board, b.board
end

function make_figure(b::Board)
    g = size(b.board, 1) 
    
    # je lepsi mit promenne soucasti structu nebo funkce, kdyz je nidke mimo nepouzivam?
    target = 0
    stop_count = 0
    delay_plot = 2.0
    gens_plot = 5
    last_update = 0.0

    isrunning_plot = Observable(false) 
    current_gen_plot = Observable(0) # ve fig, pocitani generaci
    board_plot = Observable(rand(Bool, g, g))
    
    board_plot[] .= b.board[1:g, 1:g]
    
    fig = Figure(size = (GRID_PIXELS + 200, GRID_PIXELS + 400))
    gl = GridLayout(fig[1, 1], alignmode = Outside())
    ax = Axis(gl[1, 1], 
    aspect = DataAspect(),
    title = "Game of Life (10×10)",
    xticklabelsvisible = false, yticklabelsvisible = false,
    xticksvisible = false, yticksvisible = false)
        
    colsize!(gl, 1, Fixed(GRID_PIXELS))
    rowsize!(gl, 1, Fixed(GRID_PIXELS))
    
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
        
        now = time() # https://www.jlhub.com/julia/manual/en/function/time
        if (current_gen_plot[] < target) && (now - last_update >= delay_plot)
            next_generation!(b)
            current_gen_plot[] += 1

            if current_gen_plot[] != 0 && (current_gen_plot[] % target == 0)
                stop_count += gens_plot  # reset generation count when reaching target
                isrunning_plot[] = false
            end
            print_board(board_plot[])
            last_update = now
        end
        board_plot[] = b.board[1:g, 1:g]
        #sleep(delay_plot)  - time() je asi lepsi? - sleep blokne task (https://www.jlhub.com/julia/manual/en/function/sleep) 
    end

    on(reset_button.clicks) do _
    
        isrunning_plot[] = false
        b.board = new_board()
        board_plot[] = b.board[1:g, 1:g]

        current_gen_plot[] = 0
        stop_count = 0
    end
    
    display(fig)
end

init = initialize()
make_figure(init)