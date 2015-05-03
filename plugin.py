
import bpy
import mathutils
from math import radians
import lupa
from lupa import LuaRuntime

import sys
sys.path.append("/home/o080o/Code/IS-2015")
import turtleInterpreter
import imp

imp.reload(turtleInterpreter) #force a reload, otherwise blender uses a cached copy

lua = LuaRuntime()
setPath = lua.eval("function (path) package.path = package.path .. ';' .. path .. '?.lua' end")
setPath("/home/o080o/Code/IS-2015/")
lsys = lua.require("lsys")
parser = lua.require("parser")
alphabet = lua.eval("{}")

turtle = lua.eval("{}") # make a new lua table
def rotate( quat ): # rotates the turtle
    pass

class LSystem(bpy.types.PropertyGroup):
    lsystem = bpy.props.StringProperty(subtype="FILE_PATH")
    iterations = bpy.props.IntProperty()
bpy.utils.register_class(LSystem)

class LsystemPanel(bpy.types.Panel):
    bl_label = "L-Systems"
    bl_space_type = "VIEW_3D"
    bl_region_type = "TOOLS"

    bpy.types.Object.l_systems = bpy.props.CollectionProperty(type=LSystem)

    #bpy.types.Object.l_system = bpy.props.StringProperty(subtype="FILE_PATH")
    #bpy.types.Object.iterations = bpy.props.IntProperty()

    def draw(self, context):
        layout = self.layout
        row = layout.row()
        row.label(text="Row LAbel")
        split = layout.split()
        col = layout.column(align=True)

        collection = bpy.context.active_object.l_systems
        for i in range(0, len( collection )):
            entry = collection[i]
            col.prop(entry, "lsystem", text="Rule File")
            col.prop(entry, "iterations", text="Iterations")
        #col.prop(bpy.context.active_object, "iterations")
        col.operator("prop.applysys", text="Regenerate", icon="MESH_MONKEY")
        col.operator("prop.addsys", text="Add", icon="PLUS")
        col.operator("prop.removesys", text="Remove", icon="X")

class AddSystem(bpy.types.Operator):

    bl_idname = "prop.addsys"
    bl_label = "LSystem"
    @classmethod
    def poll(self, context):
        return context.mode == "OBJECT"

    def execute(self, context):
        context.active_object.l_systems.add()
        return {"FINISHED"}

class RemoveSystem(bpy.types.Operator):
    bl_idname = "prop.removesys"
    bl_label = "LSystem"

    @classmethod
    def poll(self, context):
        return context.mode == "OBJECT"
    def execute(self, context):
        collection = context.active_object.l_systems
        collection.remove( len(collection)-1 )
        return {"FINISHED"}

class ApplySystem(bpy.types.Operator):
    bl_idname = "prop.applysys"
    bl_label = "LSystem"
    #bl_options = {"REGISTER", "UNDO"}

    @classmethod
    def poll(self, context):
        return context.mode == "OBJECT"

    def execute(self, context):
        print("Executing...")
        pos = context.active_object.location
        context.active_object.rotation_mode="QUATERNION"
        rot = context.active_object.rotation_quaternion

    
        turtle = turtleInterpreter.Turtle(lua, pos[0], pos[1], pos[2], rot)

        collection = context.active_object.l_systems
        sentence = None
        for i in range( 0, len( collection) ):
            entry = collection[i]
            fname = entry.lsystem
            itr = entry.iterations
            print("working...")
            system = parser.parseFile(fname)
            if sentence is not None:
                system.sentence = sentence
            sentence = system.step(system, itr )

        turtle.interpreter.init()
        sentence.read(sentence, turtle.interpreter) # no ':' operator in python, and self is not passed automatically
        turtle.interpreter.finalize()
        bpy.ops.object.join()

        print("Done")
        return {"FINISHED"}

def register():
    bpy.utils.register_class(LsystemPanel)
    bpy.utils.register_class(ApplySystem)
    bpy.utils.register_class(AddSystem)
    bpy.utils.register_class(RemoveSystem)
def unregister():
    bpy.utils.unregister_class(LSystem)
    bpy.utils.unregister_class(LsystemPanel)
    bpy.utils.unregister_class(ApplySystem)
    bpy.utils.unregister_class(AddSystem)
if __name__ == "__main__":
    register()

