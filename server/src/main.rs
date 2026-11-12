use axum::{Router, routing::get};

#[tokio::main]
async fn main() {
    let port = std::env::var("PORT").unwrap_or_else(|_| "3000".into());
    let app = Router::new()
        .route("/health", get(|| async { "ok" }))
        .route("/fingerprints.json", get(fingerprints));
    let listener = tokio::net::TcpListener::bind(format!("0.0.0.0:{port}"))
        .await
        .unwrap();
    axum::serve(listener, app).await.unwrap();
}

async fn fingerprints() -> impl axum::response::IntoResponse {
    let bytes = tokio::fs::read("../client/fingerprints.json").await.unwrap();
    ([(axum::http::header::CONTENT_TYPE, "application/json")], bytes)
}
