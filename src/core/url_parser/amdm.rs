use scraper::{Html, Selector};


pub fn parse(html: &str) -> Option<crate::Song> {
    let document = Html::parse_document(html);
    
    let (title, artist) = parse_metadata(&document)?;
    let text = parse_text(&document)?;

    
    return Some(crate::Song::from_str(&text, title, artist))
}

fn parse_metadata(document: &Html) -> Option<(String, String)> {
    let title_selector = Selector::parse(r#"span[itemprop="name"]"#).ok()?;
    let artist_selector = Selector::parse(r#"span[itemprop="byArtist"]"#).ok()?;

    let title = document
        .select(&title_selector)
        .next()?
        .text()
        .collect::<Vec<_>>()
        .join("");

    let artist = document
        .select(&artist_selector)
        .next()?
        .text()
        .collect::<Vec<_>>()
        .join("");


    return Some((title, artist))
}

fn parse_text(document: &Html) -> Option<String> {
    let text_selector = Selector::parse(r#"pre[itemprop="chordsBlock"]"#).ok()?;
    let text = document
            .select(&text_selector)
            .next()?
            .text()
            .collect::<Vec<_>>()
            .join("");


    Some(clean_text(&text))
}
fn clean_text(text: &str) -> String {
    text
        .replace('[', "")
        .replace("]:", "\n")
}
