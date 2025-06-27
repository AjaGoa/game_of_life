using GLMakie
using Random

global g_size = 10 
Random.seed!(123)  
board = Observable(rand(Bool, g_size, g_size))

function print_board(board)
    current_board = board[]
    for row in axes(current_board, 1) # misto 1:size, hodi mi zrovna zacatek:konec
        for col in axes(current_board, 2)
            print(current_board[row, col] ? "■ " : "∙ ")
        end
        println()  # New line after each row
    end
end

function next_generation!(board)
    current_board = board[]
    new_board = copy(current_board)
          
    for i in 1:g_size, j in 1:g_size
        neighbors = sum(current_board[max(1,i-1):min(g_size,i+1), max(1,j-1):min(g_size,j+1)]) - current_board[i,j] # max/min prevent bound errors
                
        #Any live cell with two or three live neighbours lives on to the next generation.
        if current_board[i,j] 
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
    board[] .= new_board 
    
    #=  board = new_board	Replaces the entire board array with new_board (changes the object reference).
        board .= new_board	Overwrites each element of board with values from new_board (keeps the original array).  =#
    end
    
function plotting(board)
    boardT = rotr90(board[])
    fig = Figure(size=(600, 600))
    ax = Axis(fig[1, 1], 
        aspect=DataAspect(), 
        title="Game of Life (10×10)", 
        xticklabelsvisible = false, yticklabelsvisible = false, xticksvisible = false, yticksvisible = false,
        #xgridwidth = 2, ygridwidth = 2, 
        xgridvisible = false, ygridvisible = false,
        xzoomlock = true, yzoomlock = true )
    
    heatmap!(ax, board, colormap=[:white, :black])
    #limits!(ax, 0, 50, 0, 50)
    display(fig)
end

function gol(;generations = 5, delay = 0.2)
    for gen in 1:generations
            println("Generation: $gen")
            print_board(board)
            sleep(delay)
            next_generation!(board)
            plotting(board)
    end
    
end 
gol(generations = 5, delay = 0.5)