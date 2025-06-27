 using GLMakie
using Random
Random.seed!(123)  
board = rand(Bool, 10, 10)  # Initialize a square board of given size with false (dead cells)
 function plotting(board::Array{Bool, 2})
        boardT = rotr90(board)
        fig = Figure(size=(600, 600))

        ax = Axis(fig[1, 1], 
            aspect=DataAspect(), 
            title="Game of Life (10×10)", 
            xticklabelsvisible = false, yticklabelsvisible = false, xticksvisible = false, yticksvisible = false,
            #xgridwidth = 2, ygridwidth = 2, 
            xgridvisible = false, ygridvisible = false,
            xzoomlock = true, yzoomlock = true )
            #centers_x = 1
            #centers_y = 1
        

        heatmap!(ax, boardT, colormap=[:white, :black])
        #limits!(ax, 0, 50, 0, 50)
        display(fig)
    end

function print_board(board)
        for row in axes(board, 1) # misto 1:size, hodi mi zrovna zacatek:konec
            for col in axes(board, 2)
                print(board[row, col] ? "■ " : "∙ ")
            end
            println()  # New line after each row
        end
    end
plotting(board)
print_board(board)