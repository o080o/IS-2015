import bpy
import mathutils
from math import radians
import lupa
from lupa import LuaRuntime

lua = LuaRuntime()
setPath = lua.eval("function (path) package.path = package.path .. ';' .. path .. '?.lua' end")
setPath("/home/o080o/Code/IS-2015/")
lsys = lua.require("lsys")
alphabet = lua.eval("{}")

turtle = lua.eval("{}") # make a new lua table
def rotate( quat ): # rotates the turtle
    pass



lineWidth = .1
stepSize = 1
turnAngle = radians(22.5)
shrinkFactor = .8

turtleState = [mathutils.Vector([0,0,0]),mathutils.Quaternion(), lineWidth, stepSize, turnAngle, shrinkFactor]
turtleState[1].identity()

stack = []

def init():
    turtleState[0] = mathutils.Vector([0,0,0])
    turtleState[1] = mathutils.Quaternion()
    for item in stack:
        stack.pop()
def moveTurtle(turtleState, distance):
    quat = turtleState[1]
    quat2 = quat.copy()
    quat2.conjugate()
    upVector = mathutils.Quaternion( mathutils.Vector([0,0,1]), radians(90))
    orientation = (quat * upVector * quat2)
    turtleState[0] = turtleState[0] + (orientation.axis * distance)

def rotateTurtle( turtleState, axis, angle):
    turtleState[1] = turtleState[1] * mathutils.Quaternion( axis, angle)

def draw():
    moveTurtle(turtleState, turtleState[3]/2)
    bpy.ops.mesh.primitive_cylinder_add()
    segment = bpy.context.object
    pos = turtleState[0] # a vector
    rot = turtleState[1] # a quaternion
    segment.scale = [ turtleState[2], turtleState[2], turtleState[3]/2 ]
    segment.location = [ pos[0], pos[1], pos[2] ]
    segment.rotation_mode = "QUATERNION"
    segment.rotation_quaternion = rot.copy()

    moveTurtle(turtleState, turtleState[3]/2)
def step():
    moveTurtle(turtleState, turtleState[3])
def turnL():
    rotateTurtle( turtleState, mathutils.Vector([0,-1,0]), turtleState[4] )
def turnR():
    rotateTurtle( turtleState, mathutils.Vector([0,1,0]), turtleState[4] )
def pitchU():
    rotateTurtle( turtleState, mathutils.Vector([1,0,0]), turtleState[4] )
def pitchD():
    rotateTurtle( turtleState, mathutils.Vector([-1,0,0]), turtleState[4] )
def rollL():
    rotateTurtle( turtleState, mathutils.Vector([0,0,-1]), turtleState[4] )
def rollR():
    rotateTurtle( turtleState, mathutils.Vector([0,0,1]), turtleState[4] )
def turn180():
    rotateTurtle( turtleState, mathutils.Vector([0,1,0]), radians(180) )

def shrink():
    turtleState[2] = turtleState[2] * turtleState[5]

def push():
    copy = []
    for i in range( len( turtleState ) ):
        copy.append( turtleState[i] )
    stack.append(copy)
def pop():
    copy = stack.pop()
    for i, val in enumerate( copy ):
        turtleState[i] = val

def duplicate( name ):
    def f():
        original = bpy.data.objects[name]
        bpy.ops.object.select_all(action="DESELECT")
        original.select = True
        bpy.context.scene.objects.active = original
        bpy.ops.object.duplicate(linked=True)
        new = bpy.context.object
        pos = turtleState[0] # a vector
        rot = turtleState[1] # a quaternion
        new.location = [ pos[0], pos[1], pos[2] ]
        new.rotation_mode = "QUATERNION"
        new.rotation_quaternion = rot.copy()
    return f

turtle["F"]=draw
turtle["f"]=step
turtle["+"]=turnL
turtle["-"]=turnR
turtle["&"]=pitchU
turtle["^"]=pitchD
turtle["\\"]=rollL
turtle["/"]=rollR
turtle["|"]=turn180
turtle["["]=push
turtle["]"]=pop
turtle["!"]=shrink

turtle["L"] = duplicate( "leaf" )
turtle["leaf"] = duplicate( "leaf2" )
turtle["flower"] = duplicate( "flower" )


#for n in range(10):
    #draw()
    #turnL()

systems = lua.require("ABOP_grammars")
sentence = systems.fig1_25.step( systems.fig1_25, 6)
sentence.read(sentence, turtle) # no ':' operator in python, and self is not passed automatically

#sentence = systems.fig1_26.step( systems.fig1_26, 4)
#sentence.read(sentence, turtle) # no ':' operator in python, and self is not passed automatically
