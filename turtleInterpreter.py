import bpy
import mathutils
from math import radians


class Turtle():
    def __init__(self,lua, x,y,z,rot=None, lineWidth=.1, stepSize=1, turnAngle=.7, shrinkFactor=.8):
        if rot==None:
            rot=mathutils.Quaternion()
            rot.identity()

        turtle = lua.eval("{}") # make a new lua table
        self.interpreter = turtle

        initState = [mathutils.Vector([x,y,z]),rot, lineWidth, stepSize, turnAngle, shrinkFactor]
        turtleState = [mathutils.Vector([x,y,z]),rot, lineWidth, stepSize, turnAngle, shrinkFactor]
        #turtleState[1].identity()
        stack = []
        objects = []

        # define local functions that will make closures over the turtleState
        # array and stack array
        def init():
            for i in range(len(initState)):
                turtleState[i] = initState[i]

            for item in stack:
                stack.pop()
            for o in objects:
                 objects.pop()
        def finalize():
            for o in objects:
                 o.select = True

        def moveTurtle(turtleState, distance):
            quat = turtleState[1]
            quat2 = quat.copy()
            quat2.conjugate()
            upVector = mathutils.Quaternion( mathutils.Vector([0,0,1]), radians(90))
            orientation = (quat * upVector * quat2)
            turtleState[0] = turtleState[0] + (orientation.axis * distance)

        def rotateTurtle( turtleState, axis, angle):
            turtleState[1] = turtleState[1] * mathutils.Quaternion( axis, angle)

        def draw(step=None, width=None):
            if step is None:
                step = turtleState[3]/2
            if width is None:
                width = turtleState[2]

            moveTurtle(turtleState, step)
            bpy.ops.mesh.primitive_cylinder_add()
            segment = bpy.context.object
            pos = turtleState[0] # a vector
            rot = turtleState[1] # a quaternion
            segment.scale = [ width, width, step]
            segment.location = [ pos[0], pos[1], pos[2] ]
            segment.rotation_mode = "QUATERNION"
            segment.rotation_quaternion = rot.copy()
            moveTurtle(turtleState, step)
            #add this object to the selection list
            objects.append(segment)

        def step(step=None):
            if step is None:
                step = turtleState[3]
            moveTurtle(turtleState, step)
        def turnL(theta=turnAngle, *args):
            rotateTurtle( turtleState, mathutils.Vector([0,-1,0]), radians(theta))
        def turnR(theta=turnAngle):
            rotateTurtle( turtleState, mathutils.Vector([0,1,0]), radians(theta))
        def pitchU(theta=turnAngle):
            rotateTurtle( turtleState, mathutils.Vector([1,0,0]), radians(theta))
        def pitchD(theta=turnAngle):
            rotateTurtle( turtleState, mathutils.Vector([-1,0,0]), radians(theta))
        def rollL(theta=turnAngle):
            rotateTurtle( turtleState, mathutils.Vector([0,0,-1]), radians(theta))
        def rollR(theta=turnAngle):
            rotateTurtle( turtleState, mathutils.Vector([0,0,1]), radians(theta))
        def turn180():
            rotateTurtle( turtleState, mathutils.Vector([0,1,0]), radians(180) )

        def shrink(factor=None):
            if factor is None:
                factor = turtleState[5]
            turtleState[2] = turtleState[2] * factor

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
                objects.append(new)
            return f

        def duplication(table, key):
            try:
                obj = bpy.data.objects[key]
                val = duplicate(key)
                table[key] = val
                return val
            except KeyError:
                return None

        turtle["init"] = init
        turtle["finalize"] = finalize
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




#turtlemt = lua.eval("{}") # make a new lua table
#turtlemt.__index = duplication

#setmetatable = lua.eval("function(t,mt) return setmetatable(t,mt) end")
#setmetatable(turtle, turtlemt)

#turtle["L"] = duplicate( "leaf" )
#turtle["leaf"] = duplicate( "leaf2" )
#turtle["flower"] = duplicate( "flower" )


#for n in range(10):
    #draw()
    #turnL()

#parser = lua.require("parser")
    

#system = parser.parseFile("/home/o080o/Code/IS-2015/flower.txt")

#sentence = system.step(system, 50 )
#sentence.read(sentence, turtle) # no ':' operator in python, and self is not passed automatically

#sentence = systems.fig1_26.step( systems.fig1_26, 4)
#sentence.read(sentence, turtle) # no ':' operator in python, and self is not passed automatically
