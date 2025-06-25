using GLMakie
using Random

#=function conways_game_of_life()
    # Initialize grid
    grid = falses(10, 10)
    Random.seed!(123)  # For reproducible random patterns
    grid[rand(1:10, 5), rand(1:10, 5)] .= true  # Random initial pattern

    # Create figure
    fig = Figure(size=(800, 800))
    ax = Axis(fig[1, 1], aspect=DataAspect(), title="Game of Life (10×10)")
    hidedecorations!(ax)
    hidespines!(ax)

end

# Run the simulation
conways_game_of_life()=# 

# prvne terminal

#=board = fill(false, 10, 10)
# Randomly set some cells to true
Random.seed!(124) # For reproducible random patterns, 123 asi neco jako label, nema nejaky specificky vyznam, pod seed(123) stejne hodnoty
indices = randperm(100)[1:5] # vezme 5 nahodnych hodnot z 1:10 switchne je na true, pravne rows pak cols 
board[indices] .= true =#

function gol(;g_size = 10, generations = 5, delay = 0.2)
    board = rand(Bool, g_size, g_size)  # Initialize a square board of given size with false (dead cells)

    function print_board(board)
        for row in axes(board, 1) # misto 1:size, hodi mi zrovna zacatek:konec
            for col in axes(board, 2)
                print(board[row, col] ? "■ " : "∙ ")
            end
            println()  # New line after each row
        end
    end

    function next_generation!(board)
            new_board = copy(board)
            
            for i in 1:g_size, j in 1:g_size
                neighbors = sum(board[max(1,i-1):min(g_size,i+1), max(1,j-1):min(g_size,j+1)]) - board[i,j] # max/min prevent bound errors
                
                #Any live cell with two or three live neighbours lives on to the next generation.
                if board[i,j] 
                    if neighbors == 2 || neighbors == 3
                        new_board[i,j] = true
                    
                    # Any live cell with fewer than two live neighbours dies, as if caused by under-population.
                    # Any live cell with more than three live neighbours dies, as if by over-population.
                    elseif neighbors < 2 || neighbors > 3
                        new_board[i,j] = false
                    end
                
                #Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction.
                else
                    if neighbors == 3
                        new_board[i,j] = true
                    end
                end
            end
            board .= new_board 
            #= board = new_board	Replaces the entire board array with new_board (changes the object reference).
    board .= new_board	Overwrites each element of board with values from new_board (keeps the original array).  =#
        end

    for gen in 1:generations
            println("Generation: $gen")
            print_board(board)
            sleep(delay)
            next_generation!(board)
        end
end 
gol(g_size = 10, generations = 5, delay = 0.2)