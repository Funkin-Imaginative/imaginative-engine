package imaginative.backend.macro;

import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using Lambda;
using StringTools;
using haxe.macro.ExprTools;
using haxe.macro.Tools;

// based from cne code, wanna try and do something different at some point
class CallableEventMacro {
	inline static macro function build():Array<Field> {
		var classFields = Context.getBuildFields();
		var cls:ClassType = Context.getLocalClass().get();
		var clsType:ComplexType = Context.getType('${cls.module}.${cls.name}').toComplexType();

		var tempClass = macro class TempClass {
			static var instance(default, null):Null<$clsType>;
		}
		classFields = classFields.concat(tempClass.fields);

		// gets all fields
		var values:Array<EventVar> = [];
		var hiddenValues:Array<EventVar> = [];
		for(field in classFields) {
			if (field.access.contains(AStatic)) continue;

			var hidden = false;
			if (field.meta != null)
				for (m in field.meta)
					if (m.name == ':ignore')
						hidden = true;
			if (!field.access.contains(APublic))
				hidden = true;

			switch(field.kind) {
				case FVar(type, expr):
					(hidden ? hiddenValues : values).push({
						name: field.name,
						type: type,
						expr: expr
					});
				default: continue;
			}
		}

		// add recycle option
		var func:Function = {
			args: [for (a in values) {
				value: a.expr,
				type: a.type,
				opt: false,
				name: a.name
			}],
			expr: {
				pos: Context.currentPos(),
				expr: EBlock([])
			}
		}

		var funcField:Field = {
			pos: Context.currentPos(),
			name: 'recycle',
			kind: FFun(func),
			access: [APublic, AStatic]
		}
		if (classFields.exists(field -> field.name == 'recycle'))
			funcField.access.push(AOverride);

		classFields.push(funcField);

		switch(func.expr.expr) {
			case EBlock(exprs):
				exprs.push(macro if (instance == null) instance = ${Context.parse('new ${cls.module}.${cls.name}()', Context.currentPos())});
				exprs.push(macro instance._recycle());

				// add a "set this" expr for each variable
				for (v in values) {
					var name = v.name;
					exprs.push(macro instance.$name = $i{name});
				}
				// add a "set this" expr to reset each private/hidden variables
				for (v in hiddenValues) {
					var name = v.name;
					exprs.push(macro instance.$name = ${v.expr});
				}

				exprs.push(macro return instance);
			default:
		}

		return classFields;
	}
}

typedef EventVar = {
	var name:String;
	var type:ComplexType;
	var expr:Expr;
}