using GLMakie
#=
fig = Figure(size = (3840, 2160))

ax1 = Axis(fig[1, 1],
    # Core settings
    aspect = 1,
    title = "Sliders Tutorial",
    titlegap = 28,
    titlesize = 30,
    
    # X-axis configuration
    xautolimitmargin = (50, 0),
    xgridwidth = 2,

    # Y-axis configuration
    yautolimitmargin = (0, 0),
    ygridwidth = 2,
    yticklabelpad = 14,
    yticklabelsize = 36,
    yticks = LinearTicks(20),
    yticksize = 18
)

# Set limits after Axis creation
limits!(ax1, -20, 20, -50, 8)  # xmin, xmax, ymin, ymax
=#


fig = Figure(size=(600, 600))
    
ax = Axis(fig[1, 1], 
        aspect=DataAspect(), 
        title="Game of Life (10×10)", 
        xticklabelsvisible = false, yticklabelsvisible = false, xticksvisible = false, yticksvisible = false,
        xgridwidth = 2, ygridwidth = 2, 
        xzoomlock = true, yzoomlock = true )
heatmap!(ax, bool_array, colormap=[:white, :black], colorrange=(0, 1))
limits!(ax, 0, 50, 0, 50)

plot!(ax, rand(10, 10); )
fig