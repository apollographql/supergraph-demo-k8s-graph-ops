#!/bin/bash

PORT="${1:-80}"
TESTS=(1 2)
OK_CHECK="\xE2\x9C\x85"
FAIL_MARK="\xE2\x9D\x8C"
ROCKET="\xF0\x9F\x9A\x80"

# --------------------------------------------------------------------
# QUERY 1
# --------------------------------------------------------------------
read -r -d '' QUERY_1 <<"EOF"
{
  allProducts {
    delivery {
      estimatedDelivery,
      fastestDelivery
    },
    createdBy {
      name,
      email
    }
  }
}
EOF

read -r -d '' EXP_1 <<"EOF"
{"data":{"allProducts":[{"delivery":{"estimatedDelivery":"6/25/2021","fastestDelivery":"6/24/2021"},"createdBy":{"name":"Apollo Studio Support","email":"support@apollographql.com"}},{"delivery":{"estimatedDelivery":"6/25/2021","fastestDelivery":"6/24/2021"},"createdBy":{"name":"Apollo Studio Support","email":"support@apollographql.com"}}]}}
EOF

# --------------------------------------------------------------------
# QUERY 2
# --------------------------------------------------------------------
read -r -d '' QUERY_2 <<"EOF"
{
  allProducts {
    id,
    sku,
    createdBy {
      email,
      totalProductsCreated
    }
  }
}
EOF

read -r -d '' EXP_2 <<"EOF"
{"data":{"allProducts":[{"id":"apollo-federation","sku":"federation","createdBy":{"email":"support@apollographql.com","totalProductsCreated":1337}},{"id":"apollo-studio","sku":"studio","createdBy":{"email":"support@apollographql.com","totalProductsCreated":1337}}]}}
EOF

set -e

echo Running smoke tests ...
sleep 2

for test in ${TESTS[@]}; do
  echo ""
  echo -------------------------
  echo Test $test
  echo -------------------------
  query_var="QUERY_$test"
  exp_var="EXP_$test"
  QUERY=$(echo "${!query_var}" | awk -v ORS= -v OFS= '{$1=$1}1')
  EXP="${!exp_var}"
  ACT=$(set -x; curl -X POST -H 'Content-Type: application/json' --data '{ "query": "'"${QUERY}"'" }' http://localhost:$PORT/)
  if [ "$ACT" = "$EXP" ]; then
      echo ""
      echo "Result:"
      echo "$ACT"
      echo ""
      printf "$OK_CHECK Test ${test} \n"
  else
      echo -------------------------
      printf "$FAIL_MARK Test $test\n"
      echo -------------------------
      echo "[Expected]"
      echo "$EXP"
      echo -------------------------
      echo "[Actual]"
      echo "$ACT"
      echo -------------------------
      printf "$FAIL_MARK Test $test\n"
      echo -------------------------
      exit 1
  fi
done
echo ""
printf "$OK_CHECK All tests pass! $ROCKET\n"
