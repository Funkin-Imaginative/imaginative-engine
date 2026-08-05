package imaginative.backend.macro;

import haxe.macro.Context;
import haxe.macro.Expr;

using Lambda;
using StringTools;
using haxe.macro.ExprTools;
using haxe.macro.Tools;

class ForwardMacro {
	inline static macro function buildMap(variable:String, properties:Array<Array<String>>):Array<Field> {
		var classFields = Context.getBuildFields();
		var variableType = getFieldType(classFields, variable);
		for (_ in properties) {
			var property = _[0]; var rename = _[1];
			var getName = 'get_$rename';
			var propType = getPropertyType(variableType, property);
			var varExpr:Expr = {
				expr: EConst(CIdent(variable)),
				pos: Context.currentPos()
			};

			var tempClass = macro class TempClass {
				var $rename(get, never):$propType;
				@:noCompletion function $getName():$propType
					return $varExpr.$property;
			}
			// Context.info('Field "$variable.$property" added as "$rename".', Context.currentPos());
			classFields = classFields.concat(tempClass.fields);
		}
		return classFields;
	}

	inline static macro function buildList(variable:String, properties:Array<String>):Array<Field> {
		var classFields = Context.getBuildFields();
		var variableType = getFieldType(classFields, variable);
		for (property in properties) {
			var getName = 'get_$property';
			var propType = getPropertyType(variableType, property);
			var varExpr:Expr = {
				expr: EConst(CIdent(variable)),
				pos: Context.currentPos()
			};

			var tempClass = macro class TempClass {
				var $property(get, never):$propType;
				@:noCompletion function $getName():$propType
					return $varExpr.$property;
			}
			// Context.info('Field "$variable.$property" was added.', Context.currentPos());
			classFields = classFields.concat(tempClass.fields);
		}
		return classFields;
	}

	static function getFieldType(classFields:Array<Field>, name:String):ComplexType {
		for (field in classFields) {
			if (field.name != name) continue;
			return switch (field.kind) {
				case FVar(type, _): type;
				case FProp(_, _, type, _): type;
				case FFun(_): throw 'Field "$name" is not a variable property.';
			}
		}
		throw 'Unknown field "$name" in build context.';
	}
	static function getPropertyType(variableType:ComplexType, property:String):ComplexType {
		var typePath = switch (variableType) {
			case TPath(path): path;
			case _: throw 'Forwarded variable type must be a path.';
		}
		var typeName = typePath.pack.concat([typePath.name]).join('.');
		switch (Context.getType(typeName)) {
			case TInst(cls, _):
				for (field in cls.get().fields.get()) {
					if (field.name != property) continue;
					return Context.toComplexType(Context.follow(field.type));
				}
			throw 'Unknown property "$property" on "$typeName".';
			default: throw 'Unable to resolve class type for "$typeName".';
		}
	}
}
