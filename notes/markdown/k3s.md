Title: My K3S homelab
Category: projects
Date: 2024-12-09

# Article Content

Building a Dynamic, GitOps-Driven Homelab with k3s, ArgoCD, and CI/CD

Imagine having the power to spin up fully functional Kubernetes environments for each new feature branch you create—an automated, self-healing system that integrates tightly with Git, Helm, and continuous delivery. That’s exactly what I’ve built in my homelab: a k3s-based cluster orchestrating ephemeral dev environments on-the-fly, continuously deploying changes with ArgoCD, and providing full visibility through a robust monitoring stack.

The foundation of this setup is k3s, a lightweight Kubernetes distribution that’s perfect for homelabs. On top of k3s, I’ve introduced ArgoCD to implement GitOps principles. Each time I push a branch, a GitLab CI/CD pipeline updates the repo’s configuration, and ArgoCD automatically reconciles that state in the cluster. The result is a dynamic environment—complete with its own namespace, services, and ingress—appearing as soon as a branch emerges, and disappearing just as seamlessly when that branch is removed.

Helm charts underpin the applications, ensuring consistency and reproducibility. Everything from a simple Nginx-based app to more complex microservices architectures can be defined declaratively, versioned, and easily rolled back if something goes sideways. Meanwhile, Prometheus and Grafana provide comprehensive observability: I can monitor resource usage, request latencies, and scaling behavior right from clean, insightful dashboards.

This approach goes beyond just “looking cool.” For a developer or an infrastructure engineer, it’s a workflow that scales gracefully. Imagine never manually provisioning or cleaning up a development environment again. Imagine feature branches deployed to their own isolated world, where QA and stakeholders can test without affecting others. The CI/CD pipelines handle all the grunt work, and the cluster continuously converges toward the desired state defined in Git.

If this kind of end-to-end automation sounds compelling, I’ve open-sourced a working example. Check out the repo at TODO(reworking it right now) to see how I’ve pieced everything together. Whether you’re curious about GitOps, new to Kubernetes, or just love pushing the boundaries of a homelab environment, I hope this setup sparks new ideas about how to streamline your workflow and level up your DevOps game.

