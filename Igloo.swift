//
//  Igloo.swift
//
//  Created by king on 28/04/16.
//  Copyright © 2016 king. All rights reserved.
//


import Foundation
import GLKit


protocol _GLtype { }
extension GLint: _GLtype {}
extension GLuint: _GLtype {}
extension GLfloat: _GLtype {}

extension Array where Element: _GLtype {
    func isGLtype() -> Bool {
        return true
    }
}

let Vertices :[CFloat] = [
    -1, -1, 0,
    1, -1, 0,
    -1, 1, 0,
    1, 1, 0,
]

let Indices: [GLubyte] = [
    0, 1, 2,
    1, 2, 3
]

class UniformBase {
    var slot: String!
    init(slot: String) {
        self.slot = slot
    }
    func hookup(loc: GLint) {
        preconditionFailure("This method must be overridden")
    }
}

class Uniform<T>:UniformBase {
    var value: T!
    init(slot: String, value: T) {
        self.value = value
        super.init(slot: slot)
    }
}


class UniformIv: Uniform<[GLint]> {
    let dim: Int!
    init(slot: String, value: [GLint], dim: Int = 0) {
        self.dim = dim
        super.init(slot: slot, value: value)
    }
    override func hookup(loc: GLint) {
        switch self.dim {
        case 0:
            glUniform1i(loc, value[0])
        case 1:
            glUniform1iv(loc, GLsizei(self.value.count), self.value)
        case 2:
            glUniform2iv(loc, GLsizei(self.value.count), self.value)
        case 3:
            glUniform3iv(loc, GLsizei(self.value.count), self.value)
        case 4:
            glUniform4iv(loc, GLsizei(self.value.count), self.value)
        default:
            fatalError("Should not be executed ever")
        }
    }
}

class UniformUiv: Uniform<[GLuint]> {
    let dim: Int!
    init(value: [GLuint], slot: String, dim: Int = 0) {
        self.dim = dim
        super.init(slot: slot, value: value)
    }
    override func hookup(loc: GLint) {
        switch self.dim {
        case 0:
            glUniform1ui(loc, value[0])
        case 1:
            glUniform1uiv(loc, GLsizei(self.value.count), self.value)
        case 2:
            glUniform2uiv(loc, GLsizei(self.value.count), self.value)
        case 3:
            glUniform3uiv(loc, GLsizei(self.value.count), self.value)
        case 4:
            glUniform4uiv(loc, GLsizei(self.value.count), self.value)
        default:
            fatalError("Should not be executed ever")
        }
    }
}

class UniformFv: Uniform<[GLfloat]> {
    let dim: Int!
    init(slot: String, value: [GLfloat], dim: Int = 0) {
        self.dim = dim
        super.init(slot: slot, value: value)
    }
    override func hookup(loc: GLint) {
        let s: Int = self.dim == 0 ? 0 : self.value.count / self.dim
        switch self.dim {
        case 0:
            glUniform1f(loc, value[0])
        case 1:
            glUniform1fv(loc, GLsizei(s), self.value)
        case 2:
            glUniform2fv(loc, GLsizei(s), self.value)
        case 3:
            glUniform3fv(loc, GLsizei(s), self.value)
        case 4:
            glUniform4fv(loc, GLsizei(s), self.value)
        default:
            fatalError("Should not be executed ever")
        }
    }
}



class UniformTexture: Uniform<GLuint> {
    var site: Int!
    var texture: Texture!
    init(slot: String, value: Texture, site: Int) {
        super.init(slot: slot, value: value.textureId)
        self.site = site
        self.texture = value
    }
    override func hookup(loc: GLint) {
        self.texture.bind(self.site)
        glUniform1i(loc, GLint(site))
    }
}


class Texture {
    var textureId: GLuint = GLuint()
    var format: GLint!
    var type: GLint!
    var internalFormat: GLint!
    var width: Int!
    var height: Int!
    init(format: GLint = GL_RGBA, type: GLint = GL_UNSIGNED_BYTE, wrap: GLint = GL_CLAMP_TO_EDGE, filter: GLint = GL_NEAREST, internalFormat: GLint = GL_RGBA) {
        glGenTextures(1, &self.textureId)
        glBindTexture(GLenum(GL_TEXTURE_2D), self.textureId)
        self.format = format
        self.type = type
        self.internalFormat = internalFormat
        glTexParameteri(GLuint(GL_TEXTURE_2D), GLuint(GL_TEXTURE_MIN_FILTER), filter)
        glTexParameteri(GLuint(GL_TEXTURE_2D), GLuint(GL_TEXTURE_MAG_FILTER), filter)
        glTexParameteri(GLuint(GL_TEXTURE_2D), GLuint(GL_TEXTURE_WRAP_S), wrap)
        glTexParameteri(GLuint(GL_TEXTURE_2D), GLuint(GL_TEXTURE_WRAP_T), wrap)
    }
    
    func bind(order: Int = 0) -> Texture {
        glActiveTexture(GLenum(GL_TEXTURE0 + GLint(order)))
        glBindTexture(GLenum(GL_TEXTURE_2D), self.textureId)
        return self
    }
    
    func blank(width: Int, height: Int) -> Texture {
        self.width = width; self.height = height;
        self.bind()
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, self.internalFormat, GLsizei(width), GLsizei(height), 0, GLenum(self.format), GLenum(self.type), nil)
        return self
    }
    
    func set(image: NSImage) -> Texture {
        return self.set(Utils.toCGimage(image))
    }
    
    func set(image: CGImage) -> Texture {
        let width: Int = CGImageGetWidth(image)
        let height: Int = CGImageGetHeight(image)
        var spriteData = [GLubyte](count: width * height * 4, repeatedValue: GLubyte(0))
        
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedLast.rawValue)
        print(CGImageGetColorSpace(image))
        let colorSpace = CGColorSpaceCreateDeviceRGB();
        let spriteContext = CGBitmapContextCreate(&spriteData, width, height, 8, width*4, colorSpace, bitmapInfo.rawValue)
        
        CGContextDrawImage(spriteContext, CGRectMake(0, 0, CGFloat(width) , CGFloat(height)), image)
        
        return self.set(spriteData, width: width, height: height)
    }
    
    func set<T>(bytesData: UnsafePointer<T>, width: Int, height: Int) -> Texture {
        self.width = width; self.height = height;
        self.bind()
        glTexImage2D(GLuint(GL_TEXTURE_2D), 0, self.internalFormat, GLsizei(width), GLsizei(height), 0, GLuint(self.format), UInt32(self.type), bytesData)
        
        return self
    }
    
    
    func toPointer<T>() -> UnsafePointer<T> {
        if (self.width == nil || self.height == nil) {
            fatalError("no image data stored")
        }
        let dataLength = self.width * self.height * 4;
        let data = UnsafeMutablePointer<T>.alloc(dataLength);
        self.bind();
        glGetTexImage(GLenum(GL_TEXTURE_2D), 0, GLenum(self.format), GLenum(self.type), data);
        let data_ = UnsafePointer<T>(data);
        return data_;
    }
    
    func toArray<T>() -> [T] {
        let dataLength = self.width * self.height * 4;
        let data: UnsafePointer<T> = toPointer();
        return Array(UnsafeBufferPointer<T>(start: data, count: dataLength));
    }
}


class Buffer<T> {
    var bufferId: GLuint = GLuint()
    var target: GLenum!
    init(target: GLenum) {
        self.target = target
        glGenBuffers(1, &self.bufferId)
    }
    convenience init(target: GLenum, data: [T], usage: GLenum?) {
        self.init(target: target)
        self.updateByPointer(data, size: data.count * sizeof(T), usage: usage)
    }
    func bind() -> Buffer {
        glBindBuffer(self.target, self.bufferId)
        return self
    }
    func update(data: [T], usage: GLenum?) -> Buffer {
        self.bind()
        let usage_ = usage == nil ? GLenum(GL_STATIC_DRAW) : usage
        glBufferData(self.target, data.count * sizeof(T), data, usage_!)
        return self
    }
    func updateByPointer(data: UnsafePointer<T>, size: Int, usage: GLenum?) -> Buffer {
        self.bind()
        let usage_ = usage == nil ? GLenum(GL_STATIC_DRAW) : usage
        glBufferData(self.target, size, data, usage_!)
        return self
    }
}

class VertexBuffer: Buffer<CFloat> {
    var stride: Int = 0
    init() {
        super.init(target: GLenum(GL_ARRAY_BUFFER))
    }
    convenience init(data: [CFloat], usage: GLenum?=nil, stride: Int?=nil) {
        self.init()
        if stride != nil {
            self.stride = stride!
        }
        self.updateByPointer(data, size: data.count * sizeof(CFloat), usage: usage)
    }
}

class IndexBuffer: Buffer<GLubyte> {
    init() {
        super.init(target: GLenum(GL_ELEMENT_ARRAY_BUFFER))
    }
    convenience init(data: [GLubyte], usage: GLenum?=nil) {
        self.init()
        super.updateByPointer(data, size: data.count * sizeof(GLubyte), usage: usage)
    }
}

// Vertex buffer objects
class VAO {
    var id: GLuint = GLuint() // vertex arrays object id
    var vertexBuffer: VertexBuffer?
    var indexBuffer: IndexBuffer?
    var slots = [String]()
    var sizes = [Int]()
    init() {
        glGenVertexArrays(1, &id);
    }
    func vertexBuffer(buffer: VertexBuffer) -> VAO {
        self.vertexBuffer = buffer
        return self
    }
    func indexBuffer(buffer: IndexBuffer) -> VAO {
        self.indexBuffer = buffer
        return self
    }
    func attrib(slot: String, size: Int) -> VAO {
        slots.append(slot)
        sizes.append(size)
        return self
    }
    func end(prog: Program) -> VAO {
        glBindVertexArray(id)
        if let vb = self.vertexBuffer {
            vb.bind()
            for i in 0..<self.slots.count {
                let loc = prog.getAttribLoc(slots[i])
                glEnableVertexAttribArray(GLenum(loc))
                glVertexAttribPointer(GLenum(loc), GLsizei(sizes[i]), GLenum(GL_FLOAT), GLboolean(UInt8(GL_FALSE)), GLsizei(vb.stride), nil)
            }
        }
        else {
            print("No Vertex buffer")
        }
        
        if let ib = self.indexBuffer {
            ib.bind()
        }
        
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), 0)
        glBindVertexArray(0)
        return self
    }
}

class FrameBuffer {
    var bufferId = GLuint()
    var renderBufferId: GLuint?
    init() {
        glGenFramebuffers(1, &self.bufferId)
    }
    func bind() -> FrameBuffer {
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), self.bufferId)
        return self
    }
    func attach(texture: GLuint) -> FrameBuffer{
        self.bind()
        glFramebufferTexture2D(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_TEXTURE_2D), texture, 0)
        return self
    }
    func attachBundle(textures: [GLuint]) -> FrameBuffer {
        var drawBuffers = [GLenum]()
        for i in 0..<textures.count {
            let textureId = GLenum(GL_COLOR_ATTACHMENT0 + GLint(i))
            drawBuffers.append(textureId)
            glFramebufferTexture2D(GLenum(GL_FRAMEBUFFER), textureId, GLenum(GL_TEXTURE_2D), textures[i], 0)
        }
        glDrawBuffers(GLsizei(textures.count), drawBuffers)
        return self
    }
    func attachDepth(width: Int, height: Int) -> FrameBuffer {
        var depthRenderbuffer = GLuint()
        if renderBufferId == nil {
            glGenRenderbuffers(1, &depthRenderbuffer);
            renderBufferId = depthRenderbuffer
        }
        else {
            depthRenderbuffer = renderBufferId!
        }
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), depthRenderbuffer);
        glRenderbufferStorage(GLenum(GL_RENDERBUFFER), GLenum(GL_DEPTH_COMPONENT), GLsizei(width), GLsizei(height));
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_DEPTH_ATTACHMENT), GLenum(GL_RENDERBUFFER), depthRenderbuffer);
        return self
    }
}


class Igloo {
    //    static let Quad2 = [1, -1, 1, 1, -1, 1, -1, -1]
    var gl: NSOpenGLContext!
    static let attrs = [
        NSOpenGLPixelFormatAttribute(NSOpenGLPFAOpenGLProfile),
        NSOpenGLPixelFormatAttribute(NSOpenGLProfileVersion3_2Core),
        NSOpenGLPixelFormatAttribute(NSOpenGLPFAColorSize), 24,
        NSOpenGLPixelFormatAttribute(NSOpenGLPFAAlphaSize), 8,
        NSOpenGLPixelFormatAttribute(NSOpenGLPFADoubleBuffer),
        NSOpenGLPixelFormatAttribute(NSOpenGLPFADepthSize), 32,
        0
    ]
    
    init() {
        let format = NSOpenGLPixelFormat(attributes: Igloo.attrs)
        let context = NSOpenGLContext(format: format!, shareContext: nil)
        
        self.gl = context
        self.gl.makeCurrentContext()
    }
}


class Program {
    var programHandle:GLuint!
    var locations = [String: GLint]()
    var vao: GLuint!
    var uniforms = [UniformBase]()
    
    init(vertex: String, fragment: String) {
        // Compile our vertex and fragment shaders.
        let vertexShader: GLuint = self.compileShader(vertex, shaderType: GLenum(GL_VERTEX_SHADER))
        let fragmentShader: GLuint = self.compileShader(fragment, shaderType: GLenum(GL_FRAGMENT_SHADER))
        
        // Call glCreateProgram, glAttachShader, and glLinkProgram to link the vertex and fragment shaders into a complete program.
        programHandle = glCreateProgram()
        glAttachShader(programHandle, vertexShader)
        glAttachShader(programHandle, fragmentShader)
        glLinkProgram(programHandle)
        
        // Check for any errors.
        var linkSuccess: GLint = GLint()
        glGetProgramiv(programHandle, GLenum(GL_LINK_STATUS), &linkSuccess)
        if (linkSuccess == GL_FALSE) {
            print("Failed to create shader program!")
            // TODO: Actually output the error that we can get from the glGetProgramInfoLog function.
            exit(1);
        }
    }
    
    func compileShader(shaderName: String, shaderType: GLenum) -> GLuint {
        let shaderString: NSString = self.fetchShader(shaderName)!
        let shaderHandle: GLuint = glCreateShader(shaderType)
        
        if shaderHandle == 0 {
            NSLog("Couldn't create shader")
        }
        // Conver shader string to CString and call glShaderSource to give OpenGL the source for the shader.
        var shaderStringUTF8 = shaderString.UTF8String
        var shaderStringLength: GLint = GLint(Int32(shaderString.length))
        glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength)
        
        // Tell OpenGL to compile the shader.
        glCompileShader(shaderHandle)
        
        // But compiling can fail! If we have errors in our GLSL code, we can here and output any errors.
        var compileSuccess: GLint = GLint()
        glGetShaderiv(shaderHandle, GLenum(GL_COMPILE_STATUS), &compileSuccess)
        if (compileSuccess == GL_FALSE) {
            print("Failed to compile shader!")
            var infoLog = [GLchar](count: 512, repeatedValue: 0)
            var length:GLsizei = 0
            glGetShaderInfoLog(shaderHandle, 512, &length, &infoLog)
            print("Error length: \(length)")
            fatalError(String.fromCString(infoLog)!)
        }
        
        return shaderHandle
    }
    
    func fetchShader(shaderName: String) -> NSString? {
        let shaderPath: String! = NSBundle.mainBundle().pathForResource(shaderName, ofType: "glsl")
        var error: NSError? = nil
        var shaderString: NSString?
        do {
            shaderString = try NSString(contentsOfFile:shaderPath, encoding: NSUTF8StringEncoding)
        } catch let error1 as NSError {
            error = error1
            shaderString = nil
        }
        if (shaderString == nil) {
            print("Failed to set contents shader of shader file!")
            fatalError(error!.localizedDescription)
        }
        
        return shaderString
    }
    
    func use() -> Program {
        glUseProgram(programHandle)
        return self
    }
    
    func getUniformLoc(slot: String) -> GLint {
        if self.locations[slot] == nil {
            self.locations[slot] = glGetUniformLocation(programHandle, slot)
        }
        return self.locations[slot]!
    }
    
    func getAttribLoc(slot: String) -> GLint {
        if self.locations[slot] == nil {
            self.locations[slot] = glGetAttribLocation(programHandle, slot)
        }
        return self.locations[slot]!
    }
    
    func uniform(u: UniformBase) -> Program {
        uniforms.append(u)
        return self
    }
    
    func attachVao(v: VAO) -> Program {
        self.vao = v.id
        return self
    }
    
    private func draw(drawFunc: Void -> Void) {
        if vao == nil {
            fatalError("Vertex buffer o")
        }
        
        glBindVertexArray(self.vao)
        for i in 0..<uniforms.count {
            let uniform = uniforms[i]
            uniform.hookup(self.getUniformLoc(uniform.slot))
        }
        
        drawFunc()
        glBindVertexArray(0)
    }
    
    func drawArrays(mode: GLenum, count: Int) {
        let d = {() -> () in
            glDrawArrays(mode, 0, GLsizei(count))
        }
        self.draw(d)
    }
    
    func drawElements(mode: GLenum, type: GLenum, count: Int) {
        let d = {() -> () in
            glDrawElements(mode, GLsizei(count), type, nil)
        }
        self.draw(d)
    }
    
    
}


