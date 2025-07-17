using GLMakie
using Random
using OffsetArrays

const g_size = 10 
const CELL_SIZE = 40  # pixels per cell
const GRID_PIXELS = g_size * CELL_SIZE

mutable struct Board
    board::Observable{Matrix{Bool}}  # Observable for the board state
    new_board::Matrix{Bool} # nebude delat bordel ye tady mam matrix a v board Observable?
    delay::Observable{Float64}
    gens::Observable{Int}
    isrunning::Observable{Bool}
    current_gen::Observable{Int}
    s::Observable{Int}
end

function initialize()
    return Board(
        Observable(rand(Bool, g_size, g_size)), #board
        falses(g_size, g_size), # new_board
        Observable(2.0),  # delay
        Observable(5), # gens
        Observable(false),  # isrunning
        Observable(0),  # generations
        Observable(0)
    )
end

# function print_board(b::Board)
#     println("Next")
#     for row in axes(b.board[], 1) # misto 1:size, hodi mi zrovna zacatek:konec
#         for col in axes(b.board[], 2)
#             print(b.board[][row, col] ? "■ " : "∙ ")
#         end
#         println()  # New line after each row
#     end
# end

function wrap_board(data::Matrix{Bool})
    g = size(data, 1)
    ghost = OffsetArray(falses(g+2, g+2), 0:g+1, 0:g+1)

    ghost[1:g, 1:g] .= data 
    # edges
    ghost[0, 1:g] .= data[end, :]      # top (ghost([puts data to row 0 = top halo, vsechny cols realne (1:g) matice) (data[last ROW, all cols])
    ghost[g+1, 1:g] .= data[1, :]      # bottom
    ghost[1:g, 0] .= data[:, end]      # left
    ghost[1:g, g+1] .= data[:, 1]      # right

    # corners
    ghost[0, 0] = data[end, end]
    ghost[0, g+1] = data[end, 1]
    ghost[g+1, 0] = data[1, end]
    ghost[g+1, g+1] = data[1, 1]

    return ghost
end

function next_generation!(b::Board)
    g = size(b.board[], 1)
    ghost = wrap_board(b.board[])

    for i in 1:g, j in 1:g
        neighbors = sum(ghost[i-1:i+1, j-1:j+1]) - ghost[i, j] # uz neni potreba nic checkovat

        if neighbors == 3 || (ghost[i, j] && neighbors == 2)
            b.new_board[i, j] = true
        elseif ghost[i, j] && (neighbors < 2 || neighbors > 3) 
            b.new_board[i, j] = false
        end
    end

    b.board[] = copy(b.new_board) # bez copy mi to jenom odkazuje na misto v pameti ale new_board, a to potom upravuju, takze tam bude delat bordel
end

function gol(b::Board)
    @async begin
    
    target = b.gens[] + b.s[]
    while b.current_gen[] < target
        if !b.isrunning[]
            break
        end
        next_generation!(b)
        b.current_gen[] += 1
        #print_board(b)
        sleep(b.delay[])
    end
    if b.current_gen[] != 0 && (b.current_gen[] % target == 0)
        b.s[] += b.gens[]  # reset generation count when reaching target
        
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
        
    colsize!(gl, 1, Fixed(GRID_PIXELS))
    rowsize!(gl, 1, Fixed(GRID_PIXELS))
    
    hm = heatmap!(ax, b.board, colormap = [:black, :white], colorrange = (0, 1))
    
    gen_label = Label(fig[1, 2], lift(n -> "Generation No.: $n", b.current_gen))
    slider_frame = GridLayout(fig[2, 1])
    
    delay_slider = Slider(slider_frame[1, 1], range=0.1:0.1:5.0, startvalue=2.0)
    gens_slider = Slider(slider_frame[1, 2], range=1:50, startvalue=5)
    
    delay_label = Label(slider_frame[2, 1], lift(x -> "Speed: $x", delay_slider.value))
    gens_label = Label(slider_frame[2, 2], lift(x -> "Generations: $x", gens_slider.value))

    run_button = Button(fig[3, 1], label = lift(x -> x ? "Stop" : "Run", b.isrunning))
    reset_button = Button(fig[4, 1], label="Reset")

    g = size(b.board[], 1)
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
        b.isrunning[] = false
        b.board[] = rand(Bool, g, g)
        b.current_gen[] = 0
        b.s[] = 0
    end
    
    display(fig)
end

init = initialize()
make_figure(init)