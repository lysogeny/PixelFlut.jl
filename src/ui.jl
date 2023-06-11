abstract type AbstractUI end

function update_fb!(ui::AbstractUI)
    MiniFB.mfb_update(ui.window, view(ui.buffer, :))
end

function update_loop(ui::AbstractUI)
    @info "Canvas Updater Started"
    while true
        update_fb!(ui)
        sleep(1/60)
    end
end



