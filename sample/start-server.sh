#!/bin/sh

ruby ./shogi-server --pid-file shogi-server.pid \
                    --daemon . \
                    --player-log-dir player-log-dir \
                    --floodgate-history floodgate_history.yaml \
                    floodgatetest 4000
