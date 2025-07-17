using GLMakie
using Random
# g_size ?? soucasti structu?
const g_size = 10 
const CELL_SIZE = 40  # pixels per cell
const GRID_PIXELS = g_size * CELL_SIZE

mutable struct Board
    board::Observable{Matrix{Bool}}  # Observable for the board state
    new_board::Matrix{Bool} # nebude delat bordel ye tady mam matrix a v board Observable?
    delay::Observable{Float64}
    gens::Observable{Int}
    isrunning::Observable{Bool}
end

function initialize()
    return Board(
        Observable(rand(Bool, g_size, g_size)), #board
        falses(g_size, g_size), # new_board
        Observable(2.0),  # delay
        Observable(5), # gens
        Observable(false)  # isrunning
    )
end

function next_generation!(b::Board)
    for i in 1:g_size, j in 1:g_size
        neighbors = sum(b.board[][max(1, i-1):min(g_size, i+1), max(1, j-1):min(g_size, j+1)])
        if neighbors == 3
            b.new_board[i, j] = true
        elseif b.board[][i, j]
            if neighbors == 2
                b.new_board[i, j] = true
            elseif neighbors < 2 || neighbors > 3
                b.new_board[i, j] = false
            end
        else
            println("911")
        end
    end
    b.board[] = b.new_board
end

function gol(b::Board)
    @async begin
    for gen in 1:b.gens[]
        if !b.isrunning[]
            break
        end
        next_generation!(b)
        sleep(b.delay[])
    end
    b.isrunning[] = false
    end
end

function make_figure(b::Board)
    fig = Figure(size = (GRID_PIXELS + 200, GRID_PIXELS + 400))
    gl = GridLayout(fig[1, 1], alignmode = Outside())
    ax = Axis(gl[1, 1], 
        aspect = DataAspect(),
        title = "Game of Life (10×10)",
        xticklabelsvisible = false, yticklabelsvisible = false,
        xticksvisible = false, yticksvisible = false)
        # xgridvisible = false, ygridvisible = false)
        
    colsize!(gl, 1, Fixed(GRID_PIXELS))
    rowsize!(gl, 1, Fixed(GRID_PIXELS))
    
    hm = heatmap!(ax, b.board, colormap = [:black, :white], colorrange = (0, 1))
    
    slider_frame = GridLayout(fig[2, 1])
    
    delay_slider = Slider(slider_frame[1, 1], range=0.1:0.1:5.0, startvalue=2.0)
    gens_slider = Slider(slider_frame[1, 2], range=1:50, startvalue=5)
    
    delay_label = Label(slider_frame[2, 1], lift(x -> "Speed: $x", delay_slider.value))
    gens_label = Label(slider_frame[2, 2], lift(x -> "Generations: $x", gens_slider.value))

    run_button = Button(fig[3, 1], label="Run Simulation")
    quit_button = Button(fig[4, 1], label="Quit")
    reset_button = Button(fig[5, 1], label="Reset")

    on(delay_slider.value) do value
        b.delay[] = value
    end

    on(gens_slider.value) do value
        b.gens[] = value
    end

    on(run_button.clicks) do _
        b.isrunning[] = !b.isrunning[]
        if b.isrunning[]
            gol(b)
        end
    end

    on(reset_button.clicks) do _
        b.board[] = rand(Bool, g_size, g_size)

    end
    
    display(fig)
    return (figure = fig, 
    delay_slider, 
    gens_slider, 
    run_button, 
    quit_button,
    reset_button)
    
end
init = initialize()
make_figure(init)