# This is a sample script driver for testing GCC
#
# init 
#
#chmod

# generate optimization options using Novelty Search
#
#rm -rf GCCFlagsGenerator
#git clone https://github.com/mboussaa/GCCFlagsGenerator.git
#cd GCCFlagsGenerator
#mvn clean
#mvn install;
rm -rf /shared/statistics
mkdir /shared/statistics
# avoid overhead by removing all containers 
#
echo "remove all containers";
docker stop $(docker ps -a -q);
docker rm $(docker ps -a -q);

# run CAdvisor
#
echo "run CAdvisor container";
docker run --volume=/:/rootfs:ro --volume=/var/run:/var/run:rw --volume=/sys:/sys:ro --volume=/var/lib/docker/:/var/lib/docker:ro --publish=8080:8080 --detach=true --name=cadvisor --restart=always google/cadvisor:latest -logtostderr -storage_driver=influxdb -storage_driver_host=10.0.0.22:8086 -storage_driver_db=cadvisorDB

# run InfluxDB
#
echo "run InfluxDB Time Series DB container";
docker run -d -p 8083:8083 -p 8086:8086 --expose 8090 --expose 8099 -e PRE_CREATE_DB="cadvisorDB" --name=influxdb tutum/influxdb:0.8.8
sleep 160 ;
x=0;
cd /shared/cBench_V1.1
file="/shared/GCCFlagsGenerator/NS-gcc.txt"
while read -r line
do
export CCC_OPTS=$line
COMPILER=gcc
benchmarks=*
benchmarks=`cat bench_list`
./all__delete_work_dirs
./all__create_work_dirs
for i in $benchmarks
do
if [ -d "$i" ]
then
 tmp=$PWD
 cd $i
 if [ -d "src_work" ]
 then
x=`expr $x + 1`;
  # *** process directory ***
  echo "**********************************************************"
  echo $i
  cd src_work
  ./__compile $COMPILER
  echo ""
  ls -l a.out
  echo ""
  # *************************

#rm -rf /shared/statistics
#mkdir /shared/statistics
#
for j in `seq 1 1`;
   do
    echo "#################################################### execution ####################################################"
    echo "Dataset: $j"
#  source __find_data_set $j 100 
#echo $cmd;

#rm /shared/epoch_time.csv;


   
#docker run --name=execution_container -v /shared:/shared ubuntu /bin/bash -c "cd /shared/cBench_V1.1/$i/src_work/ && time(./__run $cmd)";   
#date +%s >> "/shared/epoch_time.csv"

docker run --name=execution_container_"$x" -v /shared:/shared ubuntu /bin/bash -c " cd /shared/cBench_V1.1/$i/src_work/ && TIMEFORMAT='%3R' &&  time(./__run $j 50) 2>> /shared/statistics/time_'$i'.csv"

#date +%s >> "/shared/epoch_time.csv"
 # docker rm -f execution_container 
#cd /shared/cBench_V1.1/$i/src_work/ && TIMEFORMAT='%3R' &&  time(./__run $j 20) 2>> /shared/statistics/timeOPT_"$i".csv 

echo $x;
# request InfluxDB and get stats about memory consumption
#
echo "request InfluxDB and get stats about memory consumption";
#sleep 5;
echo "go";
sleep 100;
curl -o /shared/influxdb.json -G 'http://10.0.0.22:8086/db/cadvisorDB/series?u=root&p=root&pretty=true' --data-urlencode "q=select mean(memory_usage) from stats where container_name='execution_container_$x'";
echo "q=select mean(memory_usage) from stats where container_name='execution_container_$x'";

python /shared/JSON2CSVFILE.py $i;

#exit 0;
rm /shared/influxdb.json;


 

 docker rm -f execution_container_"$x"
done;


 fi
 cd $tmp
fi

done


echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^SEQUENCE^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"



#exit 0;
done < "$file"




