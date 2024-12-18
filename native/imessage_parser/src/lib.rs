use rustler::{Encoder, Env, NifResult, Term, Binary, NifStruct};
use imessage_database::util::typedstream::parser::TypedStreamReader;
use imessage_database::util::typedstream::models::Archivable;

#[derive(NifStruct)]
#[module = "Imessaged.TypedStream.Message.Class"]
struct Class {
    name: String,
    version: i64,
}

#[derive(NifStruct)]
#[module = "Imessaged.TypedStream.Message.Object"]
struct Object {
    class_name: String,
    version: i64,
    data: Vec<String>,
}

#[derive(NifStruct)]
#[module = "Imessaged.TypedStream.Message.Data"]
struct Data {
    values: Vec<String>,
}

fn convert_archivable<'a>(env: Env<'a>, item: &Archivable) -> Term<'a> {
    match item {
        Archivable::Object(class, data) => Object {
            class_name: class.name.clone(),
            version: class.version as i64,
            data: data.iter().map(|d| format!("{:?}", d)).collect(),
        }.encode(env),
        Archivable::Data(values) => Data {
            values: values.iter().map(|v| format!("{:?}", v)).collect(),
        }.encode(env),
        _ => format!("{:?}", item).encode(env),
    }
}

#[rustler::nif]
fn parse_typedstream<'a>(env: Env<'a>, data: Binary) -> NifResult<Term<'a>> {
    let bytes = data.as_slice();
    
    let mut reader = TypedStreamReader::from(bytes);
    match reader.parse() {
        Ok(result) => {
            let encoded: Vec<Term> = result.iter()
                .map(|item| convert_archivable(env, item))
                .collect();
            Ok(encoded.encode(env))
        },
        Err(e) => {
            Err(rustler::Error::Term(Box::new(format!("Parse error: {:?}", e))))
        }
    }
}

rustler::init!("Elixir.Imessaged.TypedStream", [parse_typedstream]); 