Tutorial Terraform: Deploy VM di Google Cloud dan Instal Docker Secara Otomatis

```
terraform init
terraform plan
terraform apply -auto-approve
```


```
ssh -i terraform-key.pem terraform@IP
sudo su
docker run -d -p 80:80 --name first_service nginx
```

```
terraform output
akses ip port 80
terraform destroy -auto-approve
```
