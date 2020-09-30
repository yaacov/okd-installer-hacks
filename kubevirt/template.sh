project=console-devel

echo "creatin project"
oc new-project $project

echo "creatin service account"
oc create sa $project

echo "giving service account admin permissions"
oc create clusterrolebinding $project --clusterrole=cluster-admin --serviceaccount=$project:$project -n ocp-devel-preview
