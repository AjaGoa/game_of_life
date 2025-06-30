using GLMakie
using Random

global g_size = 10 
board = Observable(rand(Bool, g_size, g_size))

# ... (keep all your existing functions: print_board, next_generation!) ...

size_x = 600 
size_y = 600

fig = Figure(size=(size_x, size_y))
ax = Axis(fig[1, 1], 
    aspect=DataAspect(), 
    title="Game of Life (10×10)", 
    xticklabelsvisible = false, yticklabelsvisible = false, 
    xticksvisible = false, yticksvisible = false,
    xzoomlock = true, yzoomlock = true)

slider_frame = GridLayout(fig[2, 1])
delay_slider = Slider(slider_frame[1, 1], range=0.1:0.1:2.0, startvalue=0.5)
gens_slider = Slider(slider_frame[1, 2], range=1:100, startvalue=20)
delay_label = Label(slider_frame[2, 1], lift(x -> "Speed: $x", delay_slider.value))
gens_label = Label(slider_frame[2, 2], lift(x -> "Generations: $x", gens_slider.value))

button = Button(fig[3, 1], label="Run Simulation")

# Initialize plots with current board state
live_plot = scatter!(ax, Point2f[], color=:hotpink, markersize=15, marker=:rect)
dead_plot = scatter!(ax, Point2f[], color=:lightblue, markersize=15, marker=:xcross)

# Update function that will be called in the async task
function update_plot()
    live_points = [Point2f(i,j) for i in 1:g_size, j in 1:g_size if rotr90(board[])[i,j]]
    dead_points = [Point2f(i,j) for i in 1:g_size, j in 1:g_size if !rotr90(board[])[i,j]]
    live_plot[1] = live_points
    dead_plot[1] = dead_points
    println("Generation updated")
    print_board(board)
end

# Run the simulation asynchronously
on(button.clicks) do d
    @async begin
        gens = gens_slider.value[]
        delay = delay_slider.value[]
        
        for gen in 1:gens
            next_generation!(board)
            # Update plot on the main thread
            Makie.inline!(update_plot)
            sleep(delay)
        end
    end
end

display(fig)