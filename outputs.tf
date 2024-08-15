output "instance_ips" {
  description = "The external IP addresses of the VM instances"
  value       = google_compute_instance.vm_instance[*].network_interface[0].access_config[0].nat_ip
}
