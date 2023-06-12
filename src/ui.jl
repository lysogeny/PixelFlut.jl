abstract type AbstractUI end

function update_fb!(ui::AbstractUI)
    MiniFB.mfb_update(ui.window, view(ui.buffer, :))
end

function blank(viewer::AbstractUI, rgb::UInt32)
    w, h = size(viewer)
    coordinates = [(x, y) for x in 1:w, y in 1:h]
    for (x, y) in coordinates
        viewer.buffer[x, y] = rgb
    end
end


function update_loop(ui::AbstractUI)
    @info "Canvas Updater Started"
    while true
        update_fb!(ui)
        sleep(1/60)
    end
end

Base.size(ui::AbstractUI) = size(ui.buffer)


