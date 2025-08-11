using GLMakie
using Random
using OffsetArrays

OA = OffsetArray(rand(Bool, 12, 12), 0:11, 0:11)

function wrap_board(board::AbstractMatrix{Bool})
    g = size(board, 1) - 2 # g_size + 2
    # edges
    board[0,    1:g] .= board[g, 1:g]    # top halo
    board[g+1,  1:g] .= board[1, 1:g]    # bottom halo
    board[1:g,  0]   .= board[1:g, g]    # left halo
    board[1:g, g+1]  .= board[1:g, 1]    # right halo

    # corners
    board[0,    0]   = board[g, g]
    board[0,    g+1] = board[g, 1]
    board[g+1,  0]   = board[1, g]
    board[g+1, g+1]  = board[1, 1]
    return board
end

A = wrap_board(OA)
function print_board(b::AbstractMatrix{Bool})
    println("Next")
    for row in axes(b, 1) # misto 1:size, hodi mi zrovna zacatek:konec
        for col in axes(b, 2)
            print(b[row, col] ? "■ " : "∙ ")
        end
        println()  # New line after each row
    end
end

print_board(A)