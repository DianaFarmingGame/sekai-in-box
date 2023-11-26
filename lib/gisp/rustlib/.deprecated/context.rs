// Deprecated because it's impossible to support asynchronous functions via rust

use godot::prelude::*;
use crate::parser::GispParser;

#[derive(GodotClass)]
#[class(init)]
struct GispContext {
    parent: Option<Gd<GispContext>>,

    #[var]
    fns: Dictionary,
    #[var]
    vars: Dictionary,

    #[base]
    base: Base<RefCounted>,
}

#[godot_api]
impl GispContext {
    #[func]
    fn make(&self) ->Gd<GispContext> {
        GispContext::new_gd()
    }

    #[func]
    fn duplicate(&self) ->Gd<GispContext> {
        Gd::from_init_fn(|base| {
            GispContext {
                parent: self.parent.clone(),
                fns: self.fns.clone(),
                vars: self.vars.clone(),
                base,
            }
        })
    }

    #[func]
    fn fork(&self) ->Gd<GispContext> {
        let mut nctx = GispContext::new_gd();
        nctx.bind_mut().parent = Some(self.base.clone().cast());
        nctx
    }

    #[func]
    fn get_fn(&self, name: StringName) -> Variant {
        if let Some(res) = self.fns.get(name.clone()) {
            return res
        }
        if let Some(parent) = &self.parent {
            return parent.bind().get_fn(name);
        }
        Variant::nil()
    }

    #[func]
    fn get_var(&self, name: StringName) -> Variant {
        if let Some(res) = self.vars.get(name.clone()) {
            return res
        }
        if let Some(parent) = &self.parent {
            return parent.bind().get_var(name);
        }
        Variant::nil()
    }

    #[func]
    fn set_var(&mut self, name: StringName, data: Variant) -> Variant {
        if let Some(res) = self.vars.get(name.clone()) {
            self.vars.set(name, data);
            return res
        }
        if let Some(parent) = &mut self.parent {
            return parent.bind_mut().set_var(name, data);
        }
        Variant::nil()
    }

    #[func]
    fn def_var(&mut self, name: StringName, data: Variant) {
        self.vars.set(name, data);
    }

    #[func]
    fn eval(&mut self, expr: GString) -> Variant {
        let mut parser = GispParser::make(expr);
        if parser.r_root() {
            self.exec(parser.get_result()).to_variant()
        } else {
            godot_error!("GispContext.eval: failed to tokenize expression");
            Variant::nil()
        }
    }

    #[func]
    fn exec(&mut self, tokens: VariantArray) -> VariantArray {
        return tokens.iter_shared().map(|t| self.exec_node(t)).collect();
    }

    #[func]
    fn exec_node(&mut self, node: Variant) -> Variant {
        if let Ok(node) = node.try_to::<VariantArray>() && let Some(t) = node.try_get(0) && let Ok(sn) = t.try_to::<StringName>() {
            if sn == *T_NUMBER || sn == *T_BOOL || sn == *T_KEYWORD || sn == *T_STRING {
                return node.try_get(1).unwrap_or(Variant::nil())
            }
            if sn == *T_ARRAY {
                return if let Some(body) = node.try_get(1) && let Ok(body) = body.try_to::<VariantArray>() {
                    body.iter_shared().map(|t| self.exec_node(t)).collect::<VariantArray>().to_variant()
                } else {
                    Variant::nil()
                }
            }
            if sn == *T_MAP {
                // TODO
            }
            if sn == *T_TOKEN {
                // TODO
            }
            if sn == *T_LIST {
                // TODO
            }
        } else {
            godot_error!("GispContext.exec_node: wrong node type or struct: {}", node);
        }
        Variant::nil()
    }
}

lazy_static! {
    static ref T_NUMBER: StringName = StringName::from("number");
    static ref T_BOOL: StringName = StringName::from("bool");
    static ref T_KEYWORD: StringName = StringName::from("keyword");
    static ref T_STRING: StringName = StringName::from("string");
    static ref T_ARRAY: StringName = StringName::from("array");
    static ref T_MAP: StringName = StringName::from("map");
    static ref T_TOKEN: StringName = StringName::from("token");
    static ref T_LIST: StringName = StringName::from("list");
}