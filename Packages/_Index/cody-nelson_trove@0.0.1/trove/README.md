# Attr
Attr is an attribute utility library for Roblox.

It is highly recommended to use Attr with [t by Osyris](https://github.com/osyrisrblx/t) for typechecking. The `t` library provides simple typechecking methods that can be passed into Attr as validators.

## Example Usage
```luau
local Attr = require(Path.To.Attr)
local t = require(Path.To.t)

local fooInstance: Instance = workspace.FooInstance

local function CustomValidator(attributeValue: any?): (boolean, string)
    return typeof(attributeValue) == "number", "Attribute must be a number"
end

local customExample = Attr.GetAttribute(fooInstance, "SomeAttribute", CustomValidator)
-- If `SomeAttribute` is a number, it will return the number
-- If `SomeAttribute` is not a number, it will error with the message "Attribute must be a number"

local ownerId = Attr.GetAttribute(fooInstance, "OwnerId", t.integer)
-- If `OwnerId` is an integer, it will return the integer
-- If `OwnerId` is not an integer or does not exist, it will error

local valueWithDefault = Attr.GetAttribute(fooInstance, "Value", t.string, "Default")
-- If `Value` is a string, it will return the string
-- If `Value` is not a string, it will return `Default`
```
## Types
### Attribute Validator
```luau
type AttributeValidatorFn = (any?) -> (boolean, string?)
```
An AttributeValidator is a function which takes in the current value of the attribute and returns a boolean and a string. The boolean is if it passed the check, and the string is the reason why not which will be shown when it errors.
### Attribute Filter
```luau
type AttributeFilterFn = (string, any?) -> boolean
```
An AttributeFilter is a function that takes the attribute name and value, and returns a boolean indicating whether the attribute passes the filter.

## Functions
### Attr.GetAttribute
```luau
Attr.GetAttribute(instance: Instance, attributeName: string, Validator: AttributeValidatorFn?, defaultValue: any?): any?
```
> Returns the attribute with the given name if the validator returns true. If the validator fails and a default value is provided, it returns the default; if there is no default, it errors.

### Attr.ObserveAttribute
```luau
Attr.ObserveAttribute(Callback: (any?) -> (), instance: Instance, attributeName: string, Validator: AttributeValidatorFn?, default: any?): RBXScriptConnection
```
> Calls the callback immediately with the current attribute value, using the same logic as [GetAttribute](#attrgetattribute). Returns an `RBXScriptConnection`.

### Attr.GetAttributes
```luau
Attr.GetAttributes(instance: Instance, Filter: AttributeFilterFn?): { [string]: any }
```
> Returns a dictionary of attributes (AttributeName: AttributeValue) that pass the filter (if one is provided).
