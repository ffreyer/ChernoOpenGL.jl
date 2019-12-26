function gl_clear_error()
    while ModernGL.glGetError() != ModernGL.GL_NO_ERROR
    end
    nothing
end

function gl_check_error()
    error = ModernGL.glGetError()
    error == ModernGL.GL_NO_ERROR && return ""
    # @error "An OpenGL Error has occured!"
    errors = typeof(error)[]
    while error != ModernGL.GL_NO_ERROR
        # println(error)
        push!(errors, error)
        error = ModernGL.glGetError()
    end
    # or Atom.JunoDebugger.add_breakpoint_args or whatever
    "$(join(errors, ", "))"
end

# This messes up stacktraces :(
macro GL_call(arg)
    arg_string = string(arg)
    quote
        gl_clear_error()
        $(esc(arg))
        errors = gl_check_error()
        !isempty(errors) && throw(ErrorException(
            "An OpenGL Error occured when executing $($arg_string). ($errors)"
        ))
    end
end

# NOTE: Needs to be called after a context is bound
function version_to_string()
    if GLFW.GetCurrentContext().handle == C_NULL
        throw(ErrorException("Context must be bound!"))
    end

    buffer = UInt8[]
    @GL_call ptr = ModernGL.glGetString(GL_VERSION)
    for i in 1:100
        value = unsafe_load(ptr, i)
        if value == 0x00
            break
        else
            push!(buffer, value)
        end
    end
    join(Char.(buffer))
end
