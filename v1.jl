using GLMakie
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
    xticks = False,
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

fig