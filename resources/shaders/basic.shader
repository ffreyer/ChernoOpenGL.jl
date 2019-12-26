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
uniform vec4 u_color;

void main()
{
    // 0 black
    color = u_color;
};
