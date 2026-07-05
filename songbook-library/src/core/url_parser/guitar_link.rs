use scraper::{Html, Selector};


pub fn parse(html: &str) -> Option<crate::Song> {
    let document = Html::parse_document(html);
    
    let (title, artist) = parse_metadata(&document)?;
    let text = parse_text(&document)?;

    
    return Some(crate::Song::from_str(&text, title, artist))
}

fn parse_metadata(document: &Html) -> Option<(String, String)> {
    let selector = Selector::parse("head > title").ok()?;
    let text = document
        .select(&selector)
        .next()?
        .text()
        .collect::<Vec<_>>()
        .join("");


    let divider = " Guitar Chords by Artist ";
    let len = divider.len();
    let artist = if let Some(start_index) = text.find(divider) {
        text[start_index + len..].trim().to_string()
    } else { String::from("artist") };

    let title = 
        if let Some(end_index) = text.find(divider)
    {
        text[..end_index].trim().to_string()
    } else { String::from("title") };


    return Some((title, artist))
}

fn parse_text(document: &Html) -> Option<String> {
    let text_selector = Selector::parse("pre").ok()?;


    Some(
        document
            .select(&text_selector)
            .next()?
            .text()
            .collect::<Vec<_>>()
            .join("")
    )
}
