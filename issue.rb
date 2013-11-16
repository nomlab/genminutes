# -*- coding: utf-8 -*-
##########################################
### Issue
##########################################
class Issue
  attr_accessor :project_id, :project_name, :fixed_version_id, :fixed_version_name, :status_id, :status_name, :updated_on, :create_on
end

##########################################
### Redmine Issue
### Issueを継承している ###
### 将来，Githubでも使えるようにするため
##########################################
class RedmineIssue < Issue
  attr_accessor :id, :subject, :assigned_to_id, :assigned_to_name, :project_id, :project_name,
                :fixed_version_id, :fixed_version_name, :status_id, :status_name, :created_on, :updated_on

  def self.create(data)
    issue = RedmineIssue.new
    issue.id = data["id"].to_i
    issue.subject = data["subject"]
    issue.assigned_to_id = data["assigned_to"] ? data["assigned_to"]["id"].to_i : nil
    issue.assigned_to_name = data["assigned_to"] ? data["assigned_to"]["name"] : ""
    issue.project_id  = data["project"] ? data["project"]["id"].to_i : nil
    issue.project_name  = data["project"] ? data["project"]["name"] : ""
    issue.status_id = issue_status = data["status"] ? data["status"]["id"].to_i : nil
    issue.status_name = issue_status = data["status"] ? data["status"]["name"] : ""
    issue.fixed_version_id = data["fixed_version"] ? data["fixed_version"]["id"].to_i : nil
    issue.fixed_version_name = data["fixed_version"] ? data["fixed_version"]["name"] : ""
    issue.created_on = Date.parse(data["created_on"])
    issue.updated_on = Date.parse(data["updated_on"])
    return issue
  end
end
