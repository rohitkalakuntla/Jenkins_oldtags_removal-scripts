#!/bin/bash

echo "Started the script execution"
rm -rf $WORKSPACE/project_list.txt
rm -rf $WORKSPACE/repo_check_out
rm -rf $WORKSPACE/all_deleted_tags.txt
rm -rf $WORKSPACE/tagwithnodate.txt
touch needtodeletetags.txt
touch tagwithnodate.txt
echo "The Workspace located is " $WORKSPACE
echo "The present working directory is below"
pwd
baseGitUrl="ssh://$GERRIT_ENV:29418/"
echo "The value of basegitURL is " $baseGitUrl
value=0
cd $WORKSPACE
echo "Now the present working directory is below" 
pwd
echo "Now getting all the list of projects in Gerrit repo"
ssh -p 29418 $GERRIT_ENV gerrit ls-projects > project_list.txt
echo "The list of projects in the gerrit are"
cat project_list.txt
echo "End of the project list"
echo "This build will delete tags older than " $DAYS_TO_AVOID
echo "Todays Date is"
current_date=man date
echo "--------------------------------------------------------------"
total_count=0
while read repo; do
{
        echo "Currently working on Repository" $repo;
        rm -rf $WORKSPACE/needtodeletetags.txt
        git clone $baseGitUrl$repo repo_check_out --quiet
        pushd repo_check_out
        git tag -l --format='%(refname)   %(taggerdate)' | grep "night" > $WORKSPACE/tags.txt
        git fetch origin --tags --force
        TotalNoOfTags=$(cat $WORKSPACE/tags.txt | wc -l)
                i=0
        echo "Total no of tags present in this git repo is " $TotalNoOfTags;

                 while read -r line
                 do
                        whole_tag="$line"
                        tag_path="$(echo "$whole_tag"| awk '{print $1}')"
                        tag="$(echo "$tag_path" | awk -F'/' '{print $3}')"
                        month="$(echo "$whole_tag"| awk '{print $3}')"
                        if [ -z "$month" ];then
                          echo $tag >> $WORKSPACE/tagwithnodate.txt
						elif [ "$month" = "Jan" ];then
                                month="1"
                        elif [ "$month" = "Feb" ];then
                                month="2"
                        elif [ "$month" = "Mar" ];then
                                month="3"
                        elif [ "$month" = "Apr" ];then
                                month="4"
                        elif [ "$month" = "May" ];then
                                month="5"
                        elif [ "$month" = "Jun" ];then
                                month="6"
                        elif [ "$month" = "Jul" ];then
                                month="7"
                        elif [ "$month" = "Aug" ];then
                                month="8"
                        elif [ "$month" = "Sep" ];then
                                month="9"
                        elif [ "$month" = "Oct" ];then
                                month="10"
                        elif [ "$month" = "Nov" ];then
                                month="11"
                        elif [ "$month" = "Dec" ];then
                                month="12"
						else
                          echo "Some different paramter is selected " $tag
                        fi
						day="$(echo "$whole_tag"| awk '{print $4}')"
                        year="$(echo "$whole_tag"| awk '{print $6}')"
                        temp_date="$(echo $year"/"$month"/"$day)"
                        if [ "$temp_date" != "//" ];then
                          DATEfirstnum=`date -d "$temp_date" +"%c"`
                          DateTagCreation=`date -d "$DATEfirstnum" +"%s"`
                          DateToday=`date -d "$current_date" +"%s"`
                          DAYSdif=$(($DateToday - $DateTagCreation))
                          Tag_Date=$(($DAYSdif/86400))
                          # Avoiding last 4 years 365*4 = 1460
                          cutoffdate=$DAYS_TO_AVOID
                        else
                          one="$(echo $tag | tail -c 9)"
                          year="$(echo $one | tail -c 5)"
                          month="$(echo $one | head -c 2)"
                          day="$(echo $one | tail -c 7 | head -c 2)"
                          if [ $year = "2014" ];then
                            if [ $day = "05" ];then
                            day="5"
                            fi
                          else
                          temp_date="$(echo $year"/"$month"/"$day)"
                          DATEfirstnum=`date -d "$temp_date" +"%c"`
                          DateTagCreation=`date -d "$DATEfirstnum" +"%s"`
                          DateToday=`date -d "$current_date" +"%s"`
                          DAYSdif=$(($DateToday - $DateTagCreation))
                          Tag_Date=$(($DAYSdif/86400))
                          cutoffdate=$DAYS_TO_AVOID
                          fi
                        fi
                        if [ $Tag_Date -gt $cutoffdate ];then
                                echo $tag >> $WORKSPACE/needtodeletetags.txt
                        fi
                        if [ $Tag_Date -gt $cutoffdate ];then
                                i=$((i + 1))
                        fi
                done < $WORKSPACE/tags.txt
                echo "Total number of older tags which will be deleted are " $i
                echo "The tags which needs to be deleted are saved here" $WORKSPACE"/needtodeletetags.txt"
        # Code to delete the tags from the needtodeletetags.txt
        echo "Deleting the tags from repo "$repo >> $WORKSPACE/all_deleted_tags.txt
        while read -r line
        do
                delete_tag="$line"
                echo $delete_tag >> $WORKSPACE/all_deleted_tags.txt
                git tag -d $delete_tag
                git push --delete origin $delete_tag
                total_count=$((total_count + 1))
        done < $WORKSPACE/needtodeletetags.txt
        echo "*******************************************************" >> $WORKSPACE/all_deleted_tags.txt
        # End of Code to delete the tags from the needtodeletetags.txt
        cd ..
        echo "*******************************************************"
        popd
   		rm -rf repo_check_out
}
done < project_list.txt
echo "The word count for needtodeletetags "
wc -l $WORKSPACE/needtodeletetags.txt
echo "The word count for all_deleted_tags "
wc -l $WORKSPACE/all_deleted_tags.txt
echo "The word count for all_deleted_tags tagwithnodate"
wc -l $WORKSPACE/tagwithnodate.txt
echo "The total count of tags which are deleted from all the repos are " $total_count
echo "All the deleted tags list from all the repositories are present in" $WORKSPACE"/all_deleted_tags.txt "
