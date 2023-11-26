use std::rc::Rc;

use godot::prelude::*;

#[derive(Default)]
struct GispStream {
    raw: Vec<char>,
}

impl GispStream {
    pub fn make(raw: GString) -> GispStream {
        GispStream { raw: raw.chars_checked().to_owned() }
    }

    fn rpick(&self, offset: usize) -> Option<char> {
        if (offset) < self.raw.len() {
            Some(self.raw[offset])
        } else { None }
    }

    fn len(&self) -> usize {
        self.raw.len()
    }
}

#[derive(GodotClass)]
#[class(init, rename=GispParser)]
struct GdGispParser { raw: GispParser }

#[godot_api]
impl GdGispParser {
    #[func]
    pub fn make(source: GString) -> Gd<GdGispParser> {
        Gd::from_object(GdGispParser { raw: GispParser::make(source) })
    }

    #[func]
    fn duplicate(&self) -> Gd<GdGispParser> {
        Gd::from_object(GdGispParser { raw: self.raw.clone() })
    }

    #[func]
    fn parse(&mut self) -> bool {
        self.raw.r_root()
    }

    #[func]
    fn get_result(&self) -> Array<VariantArray> {
        self.raw.get_result()
    }
}

#[derive(Clone, Default)]
struct GispParser {
    stream: Rc<GispStream>,
    offset: usize,
    result: Vec<VariantArray>,
}

impl GispParser {
    pub fn make(source: GString) -> GispParser {
        GispParser {
            stream: Rc::new(GispStream::make(source)),
            offset: 0,
            result: Vec::new(),
        }
    }

    fn rfork(&self) -> GispParser {
        GispParser {
            stream: self.stream.clone(),
            offset: self.offset,
            result: Vec::new(),
        }
    }

    fn push(&mut self, ptype: StringName, data: Variant) {
        self.result.push((&[ptype.to_variant(), data]).into());
    }

    fn r_root(&mut self) -> bool {
        let mut np = self.rfork();
        while np.r_blank() && np.r_item() {}
        if np.offset == np.stream.len() {
            self.offset = np.offset;
            self.result = np.result;
            true
        } else {
            false
        }
    }

    fn r_blank(&mut self) -> bool {
        while self.r_whitespace() && (self.r_comment() || self.r_skiper()) {}
        true
    }

    fn r_comment(&mut self) -> bool {
        if self.rpick() == Some(';') {
            self.offset += 1;
            loop {
                if let Some(c) = self.rpick() && c != '\n' {
                    self.offset += 1;
                } else {
                    return true;
                }
            }
        }
        false
    }

    fn r_skiper(&mut self) -> bool {
        if self.rpick() == Some('#') && self.rpick_offset(1) == Some(';') {
            self.offset += 2;
            let mut np = self.rfork();
            np.r_blank(); np.r_item();
            self.offset = np.offset;
            true
        } else {
            false
        }
    }

    fn r_whitespace(&mut self) -> bool {
        while let Some(c) = self.rpick() && _CS_BLANK.contains(c) {
            self.offset += 1;
        }
        true
    }

    fn r_token(&mut self) -> bool {
        if let Some(c) = self.rpick() && !_CS_N_TOKEN_HEAD.contains(c) {
            let mut chars = vec![c];
            self.offset += 1;
            while let Some(c) = self.rpick() && !_CS_N_TOKEN_BODY.contains(c) {
                chars.push(c);
                self.offset += 1;
            }
            self.push(StringName::from(&"token"), StringName::from(chars.into_iter().collect::<String>()).to_variant());
            true
        } else {
            false
        }
    }

    fn r_keyword(&mut self) -> bool {
        if self.rpick() == Some('&') {
            let poffset = self.offset;
            let mut chars = Vec::<char>::new();
            self.offset += 1;
            while let Some(c) = self.rpick() && !_CS_N_TOKEN_BODY.contains(c) {
                chars.push(c);
                self.offset += 1;
            }
            if chars.len() > 0 {
                self.push(StringName::from(&"keyword"), StringName::from(chars.into_iter().collect::<String>()).to_variant());
                true
            } else {
                self.offset = poffset;
                false
            }
        } else {
            false
        }
    }

    fn r_string(&mut self) -> bool {
        if self.rpick() == Some('"') {
            let poffset = self.offset;
            let mut chars = Vec::<char>::new();
            self.offset += 1;
            while let Some(c) = self.rpick() {
                self.offset += 1;
                match c {
                    '"' => {
                        self.push(StringName::from(&"string"), chars.into_iter().collect::<String>().to_variant());
                        return true;
                    }
                    '\\' => {
                        if let Some(nc) = self.rpick() {
                            if let Ok(s) = unescape(&([nc, c].into_iter().collect::<String>())) {
                                chars.push(s.chars().nth(0).unwrap());
                            } else {
                                chars.push(c); chars.push(nc);
                            }
                            self.offset += 1;
                        } else {
                            self.offset = poffset;
                            return false;
                        }
                    }
                    _ => {
                        chars.push(c);
                    }
                }
            }
            self.offset = poffset;
            false
        } else {
            false
        }
    }

    fn r_number(&mut self) -> bool {
        let mut chars = Vec::<char>::new();
        while let Some(c) = self.rpick() && _CS_NUMBER.contains(c) {
            chars.push(c);
            self.offset += 1;
        }
        if chars.len() > 0 {
            let s = chars.into_iter().collect::<String>();
            if s == "-" {
                self.push(StringName::from(&"number"), (-1.0).to_variant());
            } else {
                self.push(StringName::from(&"number"), s.parse::<f32>().unwrap_or(0.0).to_variant());
            }
            true
        } else {
            false
        }
    }

    fn r_bool(&mut self) -> bool {
        if self.rpick() == Some('#') && let Some(c) = self.rpick_offset(1) {
            match c {
                't' => {
                    self.offset += 2;
                    self.push(StringName::from(&"bool"), true.to_variant());
                    return true;
                }
                'f' => {
                    self.offset += 2;
                    self.push(StringName::from(&"bool"), false.to_variant());
                    return true;
                }
                _ => {
                    return false;
                }
            }
        }
        false
    }

    fn r_value(&mut self) -> bool {
        if self.r_number()
        || self.r_keyword()
        || self.r_bool()
        || self.r_string() {
            true
        } else {
            false
        }
    }

    fn r_list(&mut self) -> bool {
        if self.rpick() == Some('(') {
            let mut np = self.rfork();
            np.offset += 1;
            while np.r_blank() && np.r_item() {}
            np.r_blank();
            if np.rpick() == Some(')') {
                self.offset = np.offset + 1;
                self.push(StringName::from(&"list"), np.get_result().to_variant());
                return true
            }
        }
        false
    }

    fn r_array(&mut self) -> bool {
        if self.rpick() == Some('[') {
            let mut np = self.rfork();
            np.offset += 1;
            while np.r_blank() && np.r_item() {}
            np.r_blank();
            if np.rpick() == Some(']') {
                self.offset = np.offset + 1;
                self.push(StringName::from(&"array"), np.get_result().to_variant());
                return true
            }
        }
        false
    }

    fn r_map(&mut self) -> bool {
        if self.rpick() == Some('{') {
            let mut np = self.rfork();
            np.offset += 1;
            while np.r_blank() && (np.r_keyword() || np.r_string()) && np.r_blank() && np.r_item() {}
            np.r_blank();
            if np.rpick() == Some('}') && np.result.len() % 2 == 0 {
                self.offset = np.offset + 1;
                self.push(StringName::from(&"map"), np.get_result().to_variant());
                return true
            }
        }
        false
    }

    fn r_set(&mut self) -> bool {
        if self.r_list()
        || self.r_array()
        || self.r_map()
        {
            true
        } else {
            false
        }
    }

    fn r_item(&mut self) -> bool {
        if self.r_value()
        || self.r_set()
        || self.r_token()
        {
            true
        } else {
            false
        }
    }
}

use snailquote::unescape;

const _CS_BLANK: &str = "\u{0020}\u{0009}\u{000A}\u{000B}\u{000C}\u{00A0}\u{000D}\u{2028}\u{2029}";
const _CS_NUMBER: &str = "-0123456789.";
const _CS_N_TOKEN_HEAD: &str = concat!("&()[]{}\"$#'", "-0123456789.");
const _CS_N_TOKEN_BODY: &str = concat!("()[]{}\"'", "\u{0020}\u{0009}\u{000A}\u{000B}\u{000C}\u{00A0}\u{000D}\u{2028}\u{2029}");

impl GispParser {
    fn rpick(&self) -> Option<char> {
        self.stream.rpick(self.offset)
    }
    fn rpick_offset(&self, offset: usize) -> Option<char> {
        self.stream.rpick(self.offset + offset)
    }
    fn get_result(&self) -> Array<VariantArray> {
        Array::from(self.result.as_slice())
    }
}