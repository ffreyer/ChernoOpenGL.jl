#shader vertex
#version 330 core

// OpenGL will convert this to vec4
// location should match index from VertexAttribPointer
layout(location = 0) in vec4 position;

void main()
{
    gl_Position = position;
};


#shader fragment
#version 330 core

layout(location = 0) out vec4 color;

void main()
{
    // 0 black
    color = vec4(0.2, 0.3, 0.8, 1.0);
};
