output "sandbox_buckets" {
  description = "All sandbox buckets created by the factory"
  value = {
    for name, bucket in google_storage_bucket.sandbox :
    name => {
      name = bucket.name
      url  = bucket.url
    }
  }
}
