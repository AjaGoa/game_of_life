using GLMakie
using Random

g_size = 10 
board = Observable(rand(Bool, g_size, g_size))
const CELL_SIZE = 40  # pixels per cell
const GRID_PIXELS = g_size * CELL_SIZE

# mutable struct BoardMS
#     g_size::Int 
#     board::Matrix(Bool, g_size, g_size)
#     new_board::Similar(board)
# end
# Figure setup
function make_figure()
    fig = Figure(size = (GRID_PIXELS + 200, GRID_PIXELS + 400), backgroundcolor = :lightblue)  #space for controls

    # GridLayout to hold the axis with fixed size
    # udelat funkci jako function, vytvorit si fig jako jako funkci figure = make_figure()
    gl = GridLayout(fig[1, 1], alignmode = Outside())
    ax = Axis(gl[1, 1], 
        aspect = DataAspect(),
        title = "Game of Life (10×10)",
        xticklabelsvisible = false, yticklabelsvisible = false,
        xticksvisible = false, yticksvisible = false, 
        xgridvisible = false, ygridvisible = false, 
        backgroundcolor = :navyblue)  # Grid lines at 0, 0 a pak posunute, didnt find way how to shift them in axis by half
        # vysvetluje pozdejsi posunuti o pulku, protoze jsem na int bodech
    # Force the Axis container to be exactly GRID_PIXELS × GRID_PIXELS
    colsize!(gl, 1, Fixed(GRID_PIXELS))
    rowsize!(gl, 1, Fixed(GRID_PIXELS))

    # limits!(ax, 0, g_size, 0, g_size)

    #  for i in 0:g_size + 0.5
    #     lines!(ax, [i, i], [- 0.5, g_size+ 0.5], color=(:lightgray, 0.5))
    #     lines!(ax, [ - 0.5, g_size+0.5], [i, i], color=(:lightgray, 0.5))
    # end
    current_gen = Observable(0)

    slider_frame = GridLayout(fig[2, 1])
    
    delay_slider = Slider(slider_frame[1, 1], range=0.1:0.1:5.0, startvalue=2.0)
    gens_slider = Slider(slider_frame[1, 2], range=1:50, startvalue=5)
    
    delay_label = Label(slider_frame[2, 1], lift(x -> "Speed: $x", delay_slider.value))
    gens_label = Label(slider_frame[2, 2], lift(x -> "Generations: $x", gens_slider.value))

    button = Button(fig[3, 1], label="Run Simulation")
    button1 = Button(fig[4, 1], label="Quit")
    button2 = Button(fig[5, 1], label="Reset")

    live_plot = scatter!(ax, Point2f[], color=:lightgreen, markersize=25, marker=:rect, strokecolor=:hotpink, strokewidth=2)
    #dead_plot = scatter!(ax, Point2f[], color=:lightblue, markersize=15, marker=:xcross)

    generation_label = Label(fig[1, 2], lift(x -> "Generation: $x", current_gen), fontsize = 20, color = :black)

    display(fig)
    return (
        figure = fig,
        board = board,
        current_gen = current_gen,
        live_plot = live_plot,
        delay_slider = delay_slider,
        gens_slider = gens_slider,
        run_button = button,
        quit_button = button1,
        reset_button = button2
    )
end

# Create the figure and get the interactive elements
ui_elements = make_figure()

# Now you can access the buttons and other elements:

function print_board(board)
    current_board = board[] # [] odkazuje na hodnotu Observable, ne na Observable samotne
    for row in axes(current_board, 1) # misto 1:size, hodi mi zrovna zacatek:konec
        for col in axes(current_board, 2)
            print(current_board[row, col] ? "■ " : "∙ ")
        end
        println()  # New line after each row
    end
end

function next_generation!(board)
    # radsi udelat novou strukturu, abych nemusela kopirovat, ale mela bych je ve stejne strukture - v pameti 
    # potom jenom prohodit uvnitr struktury (to co jsem mela v tetrisu)
    # efektivnejsi v pameti
    current_board = board[] # nemusim mit kopii  - pouzit Similar - stejne  pole, stejny typ a rozmery
    new_board = copy(current_board)
          
    for i in 1:g_size, j in 1:g_size
        neighbors = sum(current_board[max(1,i-1):min(g_size,i+1), max(1,j-1):min(g_size,j+1)]) - current_board[i,j] # max/min prevent bound errors
                
        #Any live cell with two or three live neighbours lives on to the next generation.

        # kouknout na 3, mam ji tam prakticky 2x
        if neighbors == 3
            new_board[i,j] = true # Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction.
        
        elseif current_board[i,j] 
            if neighbors == 2 #|| neighbors == 3
                new_board[i,j] = true
            
            # Any live cell with fewer than two live neighbours dies, as if caused by under-population.
            # Any live cell with more than three live neighbours dies, as if by over-population.
            elseif neighbors < 2 || neighbors > 3
                new_board[i,j] = false
            end
        
        #Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction.
        else
            println("911")
        end
    end
    board[] .= new_board 
    
    #=  board = new_board	Replaces the entire board array with new_board (changes the object reference).
    board .= new_board	Overwrites each element of board with values from new_board (keeps the original array).  =#
end


function gol(;gens::Int, delay::Float64)
        
    for gen in 1:gens
        current_gen[] = gen
        rotated_board = rotr90(board[]) # predrotovat, ne pokazde znovu
        # rotr90 - predrotovat, ne pokazde znovu
        # stopy - jit k tmavsi podle toho jak dlouho je bunka mrtva - nejde true/false
        #live_points = [Point2f(i - 0.5,j - 0.5) for i in 1:g_size, j in 1:g_size if rotr90(board[])[i,j]]

        live_points = [Point2f(i - 0.5,j - 0.5) for i in 1:g_size, j in 1:g_size if rotated_board[i,j]]
        #dead_points = [Point2f(i - 0.5,j - 0.5) for i in 1:g_size, j in 1:g_size if !rotr90(board[])[i,j]]
        # - 0.5 to center the points in the grid cells, why 0.5? I guess that 0/ 1 based stuff, but 0.5? nekde se mi to vynasobilo?

        live_plot[1] = live_points
        #dead_plot[1] = dead_points
        
        
        println("Generation: $gen")
        print_board(board)
            
        sleep(delay)
      
        next_generation!(board)
    end

end 
make_figure()
on(ui_elements.run_button.clicks) do d
    #udelat si na button, jenom true false - neskonci dokud neskonci funkce 
    #tick ?? - udelat neco jednou za frame - nastavi mi delay basically, 
    @async begin # single threaded event loop , co je UI  - predtim jsem to proste zablokovala od ubdatovani, kouknout vic 
        gol(gens = gens_slider.value[], delay = delay_slider.value[])
    end
end

#=on(button1.clicks) do d
    close(fig)
end=#

on(ui_elements.reset_button.clicks) do d
    # Reset the board to a random state
    live_plot[1] = Point2f[]
    current_gen[] = 0

    board[] = rand(Bool, g_size, g_size)
end

# quit button - neco mirnesiho nez exit() ?
# chtelo by to vymyslet jak upravovat mrizlu podle zoomovani