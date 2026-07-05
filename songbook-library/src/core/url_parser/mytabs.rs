use scraper::{Html, Selector};


pub fn parse(url: &str) -> Option<crate::Song> {
    let src = reqwest::blocking::get(url).and_then(|r| r.text()).ok()?;
    let document = Html::parse_document(&src);
    
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


    let artist = if let Some(end_index) = text.find('-') {
        text[..end_index].trim().to_string()
    } else { String::from("artist") };

    let title = 
        if let Some(start_index) = text.find('-')
        && let Some(end_index) = text[start_index + 1..].find('-')
    {
        text[start_index + 1..end_index + (start_index + 1)].trim().to_string()
    } else { String::from("title") };


    return Some((title, artist))
}

fn parse_text(document: &Html) -> Option<String> {
    let text_selector = Selector::parse("pre.crd").ok()?;


    Some(
        document
            .select(&text_selector)
            .next()?
            .text()
            .collect::<Vec<_>>()
            .join("")
    )
}
