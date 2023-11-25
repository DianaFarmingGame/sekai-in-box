use godot::prelude::*;

struct GispExtension;

#[gdextension]
unsafe impl ExtensionLibrary for GispExtension {}

#[derive(GodotClass)]
#[class(base=Object)]
struct Gisp {}

#[derive(GodotClass, Default)]
struct GispStream {
    raw: Vec<char>,
}

#[godot_api]
impl GispStream {
    #[func]
    pub fn make(raw: GString) -> Gd<GispStream> {
        Gd::from_object(GispStream { raw: raw.chars_checked().to_owned() })
    }

    #[func]
    fn pick(&self, offset: u32) -> Variant {
        if (offset as usize) < self.raw.len() {
            Variant::from(self.raw[offset as usize].to_string())
        } else { Variant::nil() }
    }

    #[func]
    fn len(&self) -> u32 {
        self.raw.len() as u32
    }
}

#[godot_api]
impl IRefCounted for GispStream {
    fn init(_base: Base<RefCounted>) -> Self {
        Self::default()
    }
}

#[derive(GodotClass)]
struct GispParser {
    #[var]
    stream: Gd<GispStream>,

    #[var]
    offset: i64,

    #[var]
    result: Array<VariantArray>,
}

#[godot_api]
impl GispParser {}