mod bridge_generated;
pub mod segul_api; /* AUTO INJECTED BY flutter_rust_bridge. This line may not be accurate, and you can change it according to your needs. */

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_rust_call() {
        assert_eq!(
            segul_api::show_dna_uppercase(),
            "?-ACGTNRYSWKMBDHV.".to_string()
        );
    }
}
