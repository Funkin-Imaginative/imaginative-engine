package imaginative.backend.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

using Lambda;
using StringTools;
using haxe.macro.ExprTools;

class ConductorReactiveMacro {
	inline static macro function build():Array<Field> {
		var classFields = Context.getBuildFields();
		var tempClass = macro class TempClass {
			var _conductor_(default, null):Conductor;

			function _stepHit(target:Conductor):Void stepHit(target.curStep, _conductor_ = target);
			function _beatHit(target:Conductor):Void beatHit(target.curBeat, _conductor_ = target);
			function _measureHit(target:Conductor):Void measureHit(target.curMeasure, _conductor_ = target);

			function stepHit(step:Int, target:Conductor):Void {}
			function beatHit(beat:Int, target:Conductor):Void {}
			function measureHit(measure:Int, target:Conductor):Void {}
		}
		/* for (field in tempClass.fields)
			if (classFields.exists(f -> f.name == field.name)) {
				tempClass.fields.remove(field);
				Context.info('Removed field "${field.name}" already existed, will now ignore implementation.', Context.currentPos());
			} */
		// If you already have the function in the class, it will ignore the macro created one.
		tempClass.fields = tempClass.fields.filter((field) -> {
			final names = [for (field in classFields) field.name];
			final contains = names.contains(field.name);
			if (contains) Context.info('Field "${field.name}" already existed, will now ignore implementation.', Context.currentPos());
			return !contains;
		});
		return classFields.concat(tempClass.fields);
	}
}
#end