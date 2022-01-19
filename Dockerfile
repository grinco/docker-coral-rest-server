
#
#  Louis Mamakos <louie@transsys.com>
#  Philipp Hellmich <phil@hellmi.de>
#
#  Build a container to run the edgetpu flask daemon
#
#    docker build -t coral .
#
#  Run it something like:
#
#  docker run --restart=always --detach --name coral \
#          -p 5000:5000 --device /dev/bus/usb:/dev/bus/usb   coral:latest
#
#  It's necessary to pass in the /dev/bus/usb device to communicate with the USB stick.
#
#  You can use alternative models by putting them into a directory
#  that's mounted in the container, and then starting the container,
#  passing in environment variables MODEL and LABELS referring to
#  the files.

FROM ubuntu:20.04

WORKDIR /tmp

RUN apt-get update && apt-get install -y gnupg curl
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

RUN echo "deb https://packages.cloud.google.com/apt coral-edgetpu-stable main" | tee /etc/apt/sources.list.d/coral-edgetpu.list
RUN echo "deb https://packages.cloud.google.com/apt coral-cloud-stable main" | tee /etc/apt/sources.list.d/coral-cloud.list

RUN apt-get update && apt-get install -y python3 wget curl unzip python3-pip
RUN apt-get -y install python3-edgetpu libedgetpu1-legacy-std

# install the APP
RUN cd /tmp && \
    wget "https://github.com/robmarkcole/coral-pi-rest-server/archive/refs/tags/v1.0.zip" -O /tmp/server.zip && \
    unzip /tmp/server.zip && \
    rm -f /tmp/server.zip && \
    mv coral-pi-rest-server-1.0 /app


# fetch the models.  maybe figure a way to conditionalize this?
# create models subdirectory for volume mount of custom models
RUN  mkdir /models && \
     chdir /models && \
     wget https://dl.google.com/coral/canned_models/all_models.tar.gz -O /tmp/all_models.tar.gz && \
     tar xvf /tmp/all_models.tar.gz && \
     rm -f /tmp/all_models.tar.gz

RUN wget https://raw.githubusercontent.com/google-coral/test_data/master/ssdlite_mobiledet_coco_qat_postprocess_edgetpu.tflite -O /models/ssdlite_mobiledet_coco_qat_postprocess_edgetpu.tflite
RUN wget https://raw.githubusercontent.com/google-coral/test_data/master/efficientdet_lite3x_640_ptq_edgetpu.tflite -O /models/efficientdet_lite3x_640_ptq_edgetpu.tflite
RUN wget https://raw.githubusercontent.com/google-coral/test_data/master/efficientdet_lite3_512_ptq_edgetpu.tflite -O /models/efficientdet_lite3_512_ptq_edgetpu.tflite

WORKDIR /app

RUN  pip3 install --no-cache-dir -r requirements.txt 

ENV MODEL=ssdlite_mobiledet_coco_qat_postprocess_edgetpu.tflite \
    LABELS=coco_labels.txt \
    MODELS_DIRECTORY=/models/

EXPOSE 5000

CMD exec python3 coral-app.py --model  "${MODEL}" --labels "${LABELS}" --models_directory "${MODELS_DIRECTORY}"
