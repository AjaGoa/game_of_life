using GLMakie
using Random
using OffsetArrays

const g_size = 10
const CELL_SIZE = 40  # pixels per cell
const GRID_PIXELS = g_size * CELL_SIZE

mutable struct Board
    board::Matrix{Bool}  # Observable for the board state
    new_board::Matrix{Bool} # nebude delat bordel ye tady mam matrix a v board Observable?
    gens::Int
    s::Int # k pocitani generaci, aby spravne fungoval s/bez resetu
end

function new_board()
    A = rand(Bool, g_size + 2, g_size + 2) 
    #A[2:(g_size + 1), 2:(g_size + 1)] = rand(Bool, g_size, g_size) 
    return A
end

function initialize()
    A = new_board()      

    return Board(
        A, #board
        falses(g_size + 2, g_size + 2), # new_board
        5, # gens
        0 # s 
        )
    end

    # v1 - no offset array
function wrap_board(board::Matrix{Bool})
    g = size(board, 1)  # g_size + 2
    
    # edges
    board[1, 2:g - 1]   .= board[g-1, 2:g-1]   # top halo
    board[g, 2:g-1] .= board[2, 2:g-1]   # bottom halo
    board[2:g-1, 1]   .= board[2:g-1, g-1]   # left halo
    board[2:g-1, g] .= board[2:g-1, 2]   # right halo

    # corners
    board[1, 1]       = board[g-1, g-1]
    board[1, g]     = board[g-1, 2]
    board[g, 1]     = board[2, g-1]
    board[g, g]   = board[2, 2]
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

function next_generation!(b::Board) # ! tady by se dali passnout jenom board a new board
    g = size(b.board, 1) 
    wrap_board(b.board)  # wrap the board to handle edges

    for i in 2:(g-2), j in 2:(g-2)
        neighbors = sum(b.board[i-1:i+1, j-1:j+1]) - b.board[i, j] # uz neni potreba nic checkovat

        if neighbors == 3 || (b.board[i, j] && neighbors == 2)
            b.new_board[i, j] = true
        elseif b.board[i, j] && (neighbors < 2 || neighbors > 3) 
            b.new_board[i, j] = false
        end
    end
    b.board, b.new_board = b.new_board, b.board # bez copy mi to jenom odkazuje na misto v pameti ale new_board, a to potom upravuju, takze tam bude delat bordel
end

# function gol(b::Board)
#     # target checkuje ze mi run/stop nevytvori novou board/nezacne pocitat od zacatku
#     target = b.gens + b.s
#     if b.current_gen < target
#         next_generation!(b)
#         b.current_gen += 1
#         #print_board(b)
#         #sleep(b.delay)
#     end
#     if b.current_gen != 0 && (b.current_gen % target == 0)
#         b.s += b.gens  # reset generation count when reaching target
        
#     end
# end

function make_figure(b::Board)
    
    board_plot = Observable(b.board)
    delay_plot = Observable(2.0)
    gens_plot = Observable(b.gens)
    isrunning_plot = Observable(false)
    current_gen_plot = Observable(0)
    
    target = b.gens

    board_plot[] = b.board  
    #delay_plot[] = b.delay
    gens_plot[] = b.gens
    #current_gen_plot[] = b.current_gen
    
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

    g = size(b.board, 1)
    on(delay_slider.value) do value
        #b.delay = value
        delay_plot[] = value
    end
    
    on(gens_slider.value) do value
        b.gens = value
        gens_plot[] = value
    end
    
    on(run_button.clicks) do _
        isrunning_plot[] = !isrunning_plot[]
        if isrunning_plot[]
            target = gens_plot[] + b.s
        end
    end
    
    on(fig.scene.events.tick) do _
        isrunning_plot[] || return # if not running, do nothing
        
        if current_gen_plot[] < target
            next_generation!(b)
            current_gen_plot[] += 1

            if current_gen_plot[] != 0 && (current_gen_plot[] % target == 0)
                b.s += gens_plot[]  # reset generation count when reaching target
                isrunning_plot[] = false
            end
        end
        board_plot[] = b.board
        sleep(delay_plot[])  
    end

    on(reset_button.clicks) do _
        #b.isrunning = false
        isrunning_plot[] = false
        b.board = new_board()  
        board_plot[] = b.board

        current_gen_plot[] = 0
        b.s = 0
    end
    
    display(fig)
end

init = initialize()
make_figure(init)


#= 
checknout jestli mi funguje spravne plotovani - print_board, 
vycistit - podivat na observables, 
otazka ze jsem se jich nezbavila - jenom presunula ze struct do make_figure, potrebuju struct vubec jeste?
je on(fig.tick) mozny jeste jednodussi ? - asi udelat solo funkci,

na delay: nenasla jsem lepsi reseni nez sleep(), 
tick.delta_time vypada ze je interni soucasti, pocitani s tim mi prislo jeste horsi ? - zeptat se Ondry, 
udelat halo s offset arrays  =#