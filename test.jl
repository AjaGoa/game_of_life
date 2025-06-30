using GLMakie
using Random

global g_size = 10
board = Observable(rand(Bool, g_size, g_size))

# Figure setup
fig = Figure(size=(600, 600))
ax = Axis(fig[1, 1], 
    aspect=DataAspect(), 
    title="Game of Life (10×10)", 
    xticklabelsvisible=false, yticklabelsvisible=false,
    xticksvisible=false, yticksvisible=false,
    xzoomlock=true, yzoomlock=true
)

# Draw permanent grid lines
for i in 0.5:g_size+0.5
    lines!(ax, [i, i], [0.5, g_size+0.5], color=(:lightgray, 0.5))
    lines!(ax, [0.5, g_size+0.5], [i, i], color=(:lightgray, 0.5))
end

# Create single scatter plots that we'll update
live_plot = scatter!(ax, Point2f[], color=:hotpink, markersize=15, marker=:circle, strokecolor=:black, strokewidth=0.8)
dead_plot = scatter!(ax, Point2f[], color=:lightblue, markersize=15, marker=:xcross, strokecolor=:black, strokewidth=0.8)

# Control panel
slider_frame = GridLayout(fig[2, 1])
delay_slider = Slider(slider_frame[1, 1], range=0.1:0.1:2.0, startvalue=0.5)
gens_slider = Slider(slider_frame[1, 2], range=1:100, startvalue=10)
delay_label = Label(slider_frame[2, 1], lift(x -> "Speed: $x", delay_slider.value))
gens_label = Label(slider_frame[2, 2], lift(x -> "Generations: $x", gens_slider.value))

button = Button(fig[3, 1], label="Run Simulation")

function update_plots!(live_plot, dead_plot, board)
    rotated = rotr90(board[])
    live_points = [Point2f(i, j) for i in 1:g_size, j in 1:g_size if rotated[i, j]]
    dead_points = [Point2f(i, j) for i in 1:g_size, j in 1:g_size if !rotated[i, j]]
    
    live_plot[1] = live_points
    dead_plot[1] = dead_points
end

function gol(generations::Int, delay::Float64)
    for gen in 1:generations
        println("Generation: $gen")
        print_board(board)
        
        update_plots!(live_plot, dead_plot, board)
        next_generation!(board)
        
        sleep(delay)
        yield()
    end
end

on(button.clicks) do _
    gens = gens_slider.value[]
    delay = delay_slider.value[]
    gol(gens, delay)
end

display(fig)


#=slider_frame = GridLayout(fig[2, 1])
delay_slider = Slider(slider_frame[1, 1], range=2.0:0.1:5.0, startvalue=2.0)
gens_slider = Slider(slider_frame[1, 2], range=1:100, startvalue=5)
delay_label = Label(slider_frame[2, 1], lift(x -> "Speed: $x", delay_slider.value))
gens_label = Label(slider_frame[2, 2], lift(x -> "Generations: $x", gens_slider.value))=#

#button = Button(fig[3, 1], label="Run Simulation")

#=live_plot = scatter!(ax, Point2f[], color=:hotpink, markersize=15, marker=:circle)
dead_plot = scatter!(ax, Point2f[], 
color=:lightblue, markersize=15, marker=:xcross)=#

#=live_points = [Point2f(i,j) for i in 1:g_size, j in 1:g_size if rotr90(board[])[i,j]]
        dead_points = [Point2f(i,j) for i in 1:g_size, j in 1:g_size if !rotr90(board[])[i,j]]
        
        live_plot[1] = live_points
        dead_plot[1] = dead_points=#