struct ShaderProgramSource
    vertex::String
    fragment::String
end


mutable struct Shader
    filepath::String
    m_renderer_id::Ref{UInt32}
    uniform_locations::Dict{String, Int32}
end

function Shader(filepath::String)
    shaders = parse_shader(filepath)
    m_renderer_id = create_shader(shaders)
    shader = Shader(filepath, Ref{UInt32}(m_renderer_id), Dict{String, Int32}())
    finalizer(free, shader)
    shader
end

free(shader::Shader) = @GL_call ModernGL.glDeleteProgram(shader.m_renderer_id[])
Base.bind(shader::Shader) = @GL_call ModernGL.glUseProgram(shader.m_renderer_id[])
unbind(shader::Shader) = @GL_call ModernGL.glUseProgram(0) # NOTE maybe C_NULL


function uniform4f(shader::Shader, name, x::Float32, y::Float32, z::Float32, w::Float32)
    @GL_call ModernGL.glUniform4f(uniform_location(shader, name), x, y, z, w)
end
function uniform1i(shader::Shader, name, x::Int32)
    @GL_call ModernGL.glUniform1i(uniform_location(shader, name), x)
end

function uniform_location(shader::Shader, name)
    if haskey(shader.uniform_locations, name)
        return shader.uniform_locations[name]
    else
        @GL_call location = glGetUniformLocation(shader.m_renderer_id[], name)
        location == -1 && @warn "Uniform not found. Did you name it correctly? Is it used?"
        push!(shader.uniform_locations, name => location)
        return location
    end
end


parse_shader(shader::Shader) = parse_shader(shader.filepath)
function parse_shader(filepath::String)
    shaders = Dict{Symbol, String}()
    open(filepath, "r") do f
        write_to = :none
        for line in eachline(f)
            if startswith(line, "#shader")
                write_to = Symbol(line[9:end])
                push!(shaders, write_to => "")
                continue
            end
            if (write_to == :none) && !isempty(line)
                @warn "Ignored line\n\t>> $line"
            else
                shaders[write_to] = shaders[write_to] * "\n" * line
            end
        end
    end
    return ShaderProgramSource(
        get(shaders, :vertex, ""),
        get(shaders, :fragment, "")
    )
end


function compile_shader(gl_type, source::String)
    @GL_call id = ModernGL.glCreateShader(gl_type)
    c_str = Vector{UInt8}(source)
    shader_code_ptrs = Ptr{UInt8}[pointer(c_str)]
    len = Ref{GLint}(length(c_str))
    @GL_call ModernGL.glShaderSource(id, 1, shader_code_ptrs, len)
    @GL_call ModernGL.glCompileShader(id)

    # Error handling
    result = Ref{Int32}()
    @GL_call ModernGL.glGetShaderiv(id, ModernGL.GL_COMPILE_STATUS, result)
    if result[] == GL_FALSE
        L = Ref{Int32}()
        @GL_call ModernGL.glGetShaderiv(id, ModernGL.GL_INFO_LOG_LENGTH, L)
        msg = Vector{UInt8}(undef, L[])
        @GL_call ModernGL.glGetShaderInfoLog(id, L[], C_NULL, msg)
        @GL_call ModernGL.glDeleteShader(id)

        throw(ErrorException(
            "Failed to compile " *
            (gl_type == ModernGL.GL_VERTEX_SHADER ? "vertex" : "fragment") *
            " shader!\n\n" * String(msg)
        ))
    end

    return id
end

create_shader(x::ShaderProgramSource) = create_shader(x.vertex, x.fragment)
function create_shader(vertex_shader, fragment_shader)
    @GL_call program = ModernGL.glCreateProgram()
    @GL_call vs = compile_shader(ModernGL.GL_VERTEX_SHADER, vertex_shader)
    @GL_call fs = compile_shader(ModernGL.GL_FRAGMENT_SHADER, fragment_shader)

    @GL_call ModernGL.glAttachShader(program, vs)
    @GL_call ModernGL.glAttachShader(program, fs)
    @GL_call ModernGL.glLinkProgram(program)
    @GL_call ModernGL.glValidateProgram(program)

    # Clear temporary stuff
    @GL_call ModernGL.glDeleteShader(vs)
    @GL_call ModernGL.glDeleteShader(fs)

    return program
end
