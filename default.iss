/*
** Dims Market Bot: Look below for version number!
*/

variable string version = "2.14.8"

;******************EDIT TOTAL ORDERS HERE********************
variable(script) int totalOrders = 50
;******************EDIT TOTAL ORDERS HERE********************

variable(script) collection:int BuyOrdersTimeStamp
variable(script) collection:int SellOrdersTimeStamp
variable(script) int hadOrderBuy = 0
variable(script) int hadOrderSell = 0
variable(script) float64 totalAssetValueB = 0
variable(script) float64 totalAssetValueS = 0
variable(script) float64 iskMade = 0
variable(script) float64 ActiveBuyPrice = 0
variable(script) float64 ActiveSellPrice = 0

#include obj_items.iss

function main()
{

	variable float64 tax = 0

	echo Running: Dims Market Bot Version: ${version}
	wait 50
	if ${EVE.Is3DDisplayOn}
	{
		EVE:Toggle3DDisplay
		echo Disabling 3D Rendering
	}

	variable string SetName = ""
	variable settingsetref thisSet
	thisSet:Set[${LavishSettings[DataTrackerSettings].FindSet[${SetName}]}]
	variable filepath DATA_PATH = "${Script.CurrentDirectory}"
	variable string DATA_FILE = "Data_Tracker.xml"

	LavishSettings[DataTrackerSettings]:Clear
	LavishSettings:AddSet[DataTrackerSettings]


	if !${DATA_PATH.FileExists[${DATA_FILE}]}
	{
		echo Making data tracking file...
		LavishSettings[DataTrackerSettings]:Export[${DATA_FILE}]
	}
	else
	{
		echo Importing data tracking file...
		LavishSettings[DataTrackerSettings]:Import[${DATA_FILE}]
	}

	declarevariable EVEDB_Items obj_EVEDB_Items script
	variable int i = 1

	do
	{
		SetName:Set[${EVEDB_Items.TypeID[${i}]}]
		if !${LavishSettings[DataTrackerSettings].FindSet[${SetName}](exists)}
		{
			echo Adding setting ${EVEDB_Items.TypeID[${i}]}
			LavishSettings[DataTrackerSettings]:AddSet[${SetName}]
			LavishSettings[DataTrackerSettings].FindSet[${SetName}]:AddSetting[LastBuyPrice,0]
			LavishSettings[DataTrackerSettings].FindSet[${SetName}]:AddSetting[LastSellPrice,0]
			LavishSettings[DataTrackerSettings].FindSet[${SetName}]:AddSetting[CurrentBuyPrice,0]
			LavishSettings[DataTrackerSettings].FindSet[${SetName}]:AddSetting[CurrentSellPrice,0]
			LavishSettings[DataTrackerSettings].FindSet[${SetName}]:AddSetting[CurrentBuyID,0]
			LavishSettings[DataTrackerSettings].FindSet[${SetName}]:AddSetting[CurrentSellID,0]
			LavishSettings[DataTrackerSettings].FindSet[${SetName}]:AddSetting[LastBuyID,0]
			LavishSettings[DataTrackerSettings].FindSet[${SetName}]:AddSetting[LastSellID,0]
			LavishSettings[DataTrackerSettings].FindSet[${SetName}]:AddSetting[LastBuyTime,0]
			LavishSettings[DataTrackerSettings].FindSet[${SetName}]:AddSetting[LastSellTime,0]
			LavishSettings[DataTrackerSettings].FindSet[${SetName}]:AddSetting[TotalBought,0]
			LavishSettings[DataTrackerSettings].FindSet[${SetName}]:AddSetting[TotalSold,0]
			LavishSettings[DataTrackerSettings].FindSet[${SetName}]:AddSetting[FilledBuyOrderCount,0]
			LavishSettings[DataTrackerSettings].FindSet[${SetName}]:AddSetting[FilledSellOrderCount,0]
		}
		LavishSettings[DataTrackerSettings]:Export[${DATA_FILE}]
	}
	while ${i:Inc} <= ${totalOrders}

	SetName:Set["Modifies"]
	thisSet:Set[${LavishSettings[DataTrackerSettings].FindSet[${SetName}]}]
	if !${LavishSettings[DataTrackerSettings].FindSet[${SetName}](exists)}
	{
		echo Adding setting "Modifies"
		LavishSettings[DataTrackerSettings]:AddSet[${SetName}]
		LavishSettings[DataTrackerSettings].FindSet[${SetName}]:AddSetting[Modifications,0]
		LavishSettings[DataTrackerSettings].FindSet[${SetName}]:AddSetting[DateTime,${Time.Timestamp}]
		LavishSettings[DataTrackerSettings].FindSet[${SetName}]:AddSetting[TotalISKMadeCount, 0]
		LavishSettings[DataTrackerSettings]:Export[${DATA_FILE}]
	}

	EVE:Execute[OpenHangarFloor]
	wait 15
	EVE:Execute[OpenShipHangar]
	wait 15
	EVE:Execute[OpenWallet]
	wait 15
	Me.Station:StackAllHangarItems
	wait 12


	i:Set[1]

	variable float64 TotalActiveBuyISK = 0
	variable float64 TotalActiveSellISK = 0

	do
	{
		i:Set[1]
		do
		{
			ActiveBuyPrice:Set[0]
			ActiveSellPrice:Set[0]
			tax:Set[0]
			echo Getting Order Number: ${i}
			call mine ${EVEDB_Items.TypeID[${i}]} ${EVEDB_Items.BuyOrderQuan[${i}]} ${EVEDB_Items.SellOrderQuan[${i}]} ${EVEDB_Items.Stock[${i}]} ${EVEDB_Items.BuyMargin[${i}]} ${EVEDB_Items.SellMargin[${i}]}

			SetName:Set[${EVEDB_Items.TypeID[${i}]}]
			thisSet:Set[${LavishSettings[DataTrackerSettings].FindSet[${SetName}]}]

			TotalActiveSellISK:Set[${Math.Calc[${ActiveSellPrice} + ${TotalActiveSellISK}]}]
			TotalActiveBuyISK:Set[${Math.Calc[${ActiveBuyPrice} + ${TotalActiveBuyISK}]}]

			tax:Set[${Math.Calc[(${TotalActiveBuyISK} * 0.0020) + (${TotalActiveSellISK} * 0.0070)]}]
			iskMade:Set[${Math.Calc[(${TotalActiveSellISK} - ${TotalActiveBuyISK}]}]

			echo *** My Current Total Asset Value For Item Number ${i} of ${totalOrders} is:
			echo *** <ONE-BILL>.00 - TOTAL ASSESTS AT SELL PRICE ::: TOTAL ASSESTS AT BUY PRICE
			echo *** ${TotalActiveSellISK} ::: ${TotalActiveBuyISK}
			echo *** <ONE-BILL>.00 - TOTAL ISK MADE BY A TURNOVER INCLUDING TAXES ::: TOTAL ISK MADE BY A TURNOVER NOT INCLUDING TAXES
			echo *** ${Math.Calc[(${iskMade} - ${tax})]} ::: ${iskMade}
			echo *** <ONE-BILL>.00 - TOTAL ISK MADE BY THIS ITEM INCLUDING TAXES (ALL TIME) ::: TOTAL BUY ORDERS (ALL TIME) ::: TOTAL SELL ORDERS (ALL TIME)
			echo *** ${Math.Calc[(${thisSet.FindSetting[TotalSold]} - ${thisSet.FindSetting[TotalBought]}) - (${thisSet.FindSetting[TotalBought]} * 0.0020 + ${thisSet.FindSetting[TotalSold]} * 0.0070)]} ::: ${thisSet.FindSetting[FilledBuyOrderCount]} ::: ${thisSet.FindSetting[FilledSellOrderCount]}
			echo *** <ONE-BILL>.00 - TOTAL NAV VALUE SO FAR
			echo *** ${Math.Calc[((${TotalActiveBuyISK} * 0.24 ) + ${Me.Wallet.Balance} + ${TotalActiveSellISK})]}

			if ${i} == ${totalOrders}
			{
				SetName:Set["Modifies"]
				thisSet:Set[${LavishSettings[DataTrackerSettings].FindSet[${SetName}]}]
				LavishSettings[DataTrackerSettings].FindSet[${SetName}]:AddSetting[TotalISKMadeCount, ${Math.Calc[${thisSet.FindSetting[TotalISKMadeCount]} + 1]}]
				LavishSettings[DataTrackerSettings].FindSet[${SetName}]:AddSetting[${thisSet.FindSetting[TotalISKMadeCount]}, ${Math.Calc[((${TotalActiveBuyISK} * 0.24 ) + ${Me.Wallet.Balance} + ${TotalActiveSellISK})]}]
				LavishSettings[DataTrackerSettings]:Export[${DATA_FILE}]
				totalAssetValueB:Set[0]
				totalAssetValueS:Set[0]
				iskMade:Set[0]
				TotalActiveBuyISK:Set[0]
				TotalActiveSellISK:Set[0]
			}
			wait ${Math.Rand[20]:Inc[50]}
		}
		while ${i:Inc} <= ${totalOrders}
	}
	while 1 == 1
}


;****************************************************************************************************************************************************************************************************************************************************

function updateIDbuySell(int db_TypeID, float64 myPriceBuy, float64 myPriceSell, float64 db_BuyMargin, float64 db_SellMargin, int64 myBuyID, int64 mySellID, int cantModBuy, int cantModSell, float64 myOrderBuyMinimum, float64 myOrderSellMinimum)
{
	variable iterator OrderIterator
	variable int OrdersCount
	variable index:int TypeIDs
	variable index:string TypeNames

	variable index:marketorder buyOrders
	variable index:marketorder sellOrders

	variable int Station = ${Me.StationID}

	variable string name = ""

	variable int i = 1

	variable float64 BuyModNum = 0
	variable float64 SellModNum = 0

	variable int64 theOrderBuyID = 0
	variable int64 theOrderSellID = 0

	variable int dontBuy = 0
	variable int dontSell = 0

	variable float64 modifiedFilteredBuyPriceMargin = 0
	variable float64 modifiedFilteredSellPriceMargin = 0
	variable float64 filteredBuyPriceMargin = 0
	variable float64 filteredSellPriceMargin = 0

	variable float64 numberOfActiveBuyOrders = 0
	variable float64 numberOfActiveSellOrders = 0

	variable float64 highestFilteredBuyPrice = 0
	variable float64 lowestFilteredSellPrice = 1000000000000000000
	variable float64 nextLowestFilteredSellPrice = 2000000000000000000
	variable float64 nextHighestFilteredBuyPrice = 0

	variable float64 margin = 0
	variable float64 compar = 0

	variable float64 priceOne = 0
	variable float64 priceTwo = 0

	variable string IndexName
	variable string MemberName = Price

	variable string SetName = ""
	variable settingsetref thisSet
	thisSet:Set[${LavishSettings[DataTrackerSettings].FindSet[${SetName}]}]
	variable filepath DATA_PATH = "${Script.CurrentDirectory}"
	variable string DATA_FILE = "Data_Tracker.xml"
	SetName:Set[${db_TypeID}]
	thisSet:Set[${LavishSettings[DataTrackerSettings].FindSet[${SetName}]}]

	Orders:Clear
	EVE:ClearMarketOrderCache
	EVE:FetchMarketOrders[${db_TypeID}]

	i:Set[1]

	do
	{
		EVE:GetMarketOrders[buyOrders, ${db_TypeID},"Buy"]
		wait 10
		if ${i} > 5
		break
		i:Inc
	}
	while !${buyOrders.Used}

	i:Set[1]

	do
	{
		EVE:GetMarketOrders[sellOrders, ${db_TypeID},"Sell"]
		wait 10
		if ${i} > 5
		break
		i:Inc
	}
	while !${sellOrders.Used}

	IndexName:Set["buyOrders"]

	i:Set[1]

	while ${i} <= ${${IndexName}.Used}
	{
		if ( ${i} == 1 ) || ${${IndexName}[${Math.Calc[${i}-1]}].${MemberName}} >= ${${IndexName}[${i}].${MemberName}}
		{
			i:Inc
		}
		else
		{
			${IndexName}:Swap[${i}, ${Math.Calc[${i}-1]}]
			i:Dec
		}
	}

	buyOrders:GetIterator[OrderIterator]

	if ${OrderIterator:First(exists)}
	do
	{
		if ${OrderIterator.Value.IsBuyOrder}
		{
			if ${OrderIterator.Value.StationID} == ${Station}
			{
				if ${OrderIterator.Value.Price} > ${highestFilteredBuyPrice} && ${OrderIterator.Value.ID} != ${myBuyID} && ${OrderIterator.Value.QuantityRemaining} >= ${myOrderBuyMinimum} && ${OrderIterator.Value.QuantityRemaining} >= ${myOrderSellMinimum}
				{
					name:Set[${OrderIterator.Value.Name}]
					highestFilteredBuyPrice:Set[${OrderIterator.Value.Price}]
					theOrderBuyID:Set[${OrderIterator.Value.ID}]
				}
				if ${OrderIterator.Value.Price} < ${highestFilteredBuyPrice} && ${OrderIterator.Value.ID} != ${myBuyID} && ${OrderIterator.Value.QuantityRemaining} >= ${myOrderBuyMinimum} && ${OrderIterator.Value.QuantityRemaining} >= ${myOrderSellMinimum} && ${OrderIterator.Value.Price} > ${nextHighestFilteredBuyPrice}
				{
					nextHighestFilteredBuyPrice:Set[${OrderIterator.Value.Price}]
				}
			}
		}
	}
	while ${OrderIterator:Next(exists)}

	i:Set[1]

	IndexName:Set["sellOrders"]

	while ${i} <= ${${IndexName}.Used}
	{
		if ( ${i} == 1 ) || ${${IndexName}[${Math.Calc[${i}-1]}].${MemberName}} <= ${${IndexName}[${i}].${MemberName}}
		{
			i:Inc
		}
		else
		{
			${IndexName}:Swap[${i}, ${Math.Calc[${i}-1]}]
			i:Dec
		}
	}

	sellOrders:GetIterator[OrderIterator]

	if ${OrderIterator:First(exists)}
	do
	{
		if ${OrderIterator.Value.IsSellOrder}
		{
			if ${OrderIterator.Value.StationID} == ${Station}
			{
				if ${OrderIterator.Value.Price} < ${lowestFilteredSellPrice} && ${OrderIterator.Value.ID} != ${mySellID} && ${OrderIterator.Value.QuantityRemaining} >= ${myOrderSellMinimum} && ${OrderIterator.Value.QuantityRemaining} >= ${myOrderBuyMinimum}
				{
					lowestFilteredSellPrice:Set[${OrderIterator.Value.Price}]
					theOrderSellID:Set[${OrderIterator.Value.ID}]
				}
				if ${OrderIterator.Value.Price} > ${lowestFilteredSellPrice} && ${OrderIterator.Value.ID} != ${mySellID} && ${OrderIterator.Value.QuantityRemaining} >= ${myOrderSellMinimum} && ${OrderIterator.Value.QuantityRemaining} >= ${myOrderBuyMinimum} && ${OrderIterator.Value.Price} < ${nextLowestFilteredSellPrice}
				{
					nextLowestFilteredSellPrice:Set[${OrderIterator.Value.Price}]
				}
			}
		}
	}
	while ${OrderIterator:Next(exists)}

	if (${sellOrders.Used} < 6) || (${buyOrders.Used} < 6)
	{
		echo Skipping this item becasue there are not enough orders on the market Error buy ${buyOrders.Used}  :: Error Sell : ${sellOrders.Used}
		return
	}

	if ${highestFilteredBuyPrice} < 10 || ${lowestFilteredSellPrice} < 10
	{
		echo Prices Less than 10.00 ISK Stopping trading!
		return
	}

	filteredBuyPriceMargin:Set[${Math.Calc[(${highestFilteredBuyPrice} / ${nextHighestFilteredBuyPrice})]}]
	filteredSellPriceMargin:Set[${Math.Calc[(${nextLowestFilteredSellPrice} / ${lowestFilteredSellPrice})]}]
	modifiedFilteredBuyPriceMargin:Set[${Math.Calc[((((${highestFilteredBuyPrice} / ${nextHighestFilteredBuyPrice}) + ${filteredSellPriceMargin}) * 0.0005))]}]
	modifiedFilteredSellPriceMargin:Set[${Math.Calc[((((${nextLowestFilteredSellPrice} / ${lowestFilteredSellPrice}) + ${filteredBuyPriceMargin}) * 0.0005))]}]
	modifiedFilteredBuyPriceMargin:Set[${Math.Calc[(${filteredSellPriceMargin} + ${modifiedFilteredBuyPriceMargin})]}]
	modifiedFilteredSellPriceMargin:Set[${Math.Calc[(${filteredBuyPriceMargin} + ${modifiedFilteredSellPriceMargin})]}]

	if ${filteredBuyPriceMargin} > ${modifiedFilteredBuyPriceMargin}
	{
		echo Inner buy margins on item ${name} not met. This means theres a large margin in the item with a buy order filling the gap. Modding Order Buy.
		echo ${filteredBuyPriceMargin} should be greater than ${modifiedFilteredBuyPriceMargin}
		dontBuy:Set[-1]
	}

	if ${filteredSellPriceMargin} > ${modifiedFilteredSellPriceMargin}
	{
		echo Inner sell margins on item ${name} not met. This means theres a large margin in the item with a sell order filling the gap. Modding Order Sell.
		echo ${filteredSellPriceMargin} should be greater than ${modifiedFilteredSellPriceMargin}
		dontSell:Set[-1]
	}

	if ${highestFilteredBuyPrice} > ${thisSet.FindSetting[LastSellPrice]} && (${Time.Timestamp} < (${Math.Calc[${thisSet.FindSetting[LastBuyTime]}]} + 38800)) && (${thisSet.FindSetting[LastSellPrice]} != 0)
	{
		BuyModNum:Set[${Math.Calc[${thisSet.FindSetting[LastBuyPrice]} / 1.03]}]
		echo OOPS! Market bubble! Changing buy trading for item ${name} setting price to ${BuyModNum}
		dontBuy:Set[1]
	}

	if ${lowestFilteredSellPrice} < ${thisSet.FindSetting[LastBuyPrice]}  && (${Time.Timestamp} < (${Math.Calc[${thisSet.FindSetting[LastSellTime]}]} + 38800)) && (${thisSet.FindSetting[LastBuyPrice]} != 0)
	{
		SellModNum:Set[${Math.Calc[${thisSet.FindSetting[LastSellPrice]} * 1.03]}]
		echo OOPS! Market Bubble! Changing Sell trading for item ${name} setting price to ${SellModNum}
		dontSell:Set[1]
	}

	margin:Set[${Math.Calc[(${lowestFilteredSellPrice} / ${highestFilteredBuyPrice})]}]
	compar:Set[${Math.Calc[(${lowestFilteredSellPrice} - ${highestFilteredBuyPrice})]}]


	if (${compar} <= 0 )
	{
		echo Error Negative Comparison!!!
		return
	}

	if (${highestFilteredBuyPrice} >= ${lowestFilteredSellPrice})
	{
		echo Error Negative Comparison!!!
		return
	}

	echo Buy Order Highest is ${highestFilteredBuyPrice} next highest is ${nextHighestFilteredBuyPrice}

	if ${myPriceBuy} != 0 && ${cantModBuy} != 1 && ${theOrderBuyID} != ${myBuyID} && ${dontBuy} != 1
	{

		if ( ${dontBuy} == -1 )
		{
			priceOne:Set[${nextHighestFilteredBuyPrice}]
			priceTwo:Set[0.01]
			echo Undercutting next highest buy order! : ${name} : ${priceOne} Margins Between!
			call modOrderBuy ${db_TypeID} ${priceOne} ${priceTwo} ${myPriceBuy}
		}
		elseif  ${Math.Calc[(${nextHighestFilteredBuyPrice} / ${nextLowestFilteredSellPrice})]} >= ${db_BuyMargin} && ${margin} >= ${db_BuyMargin} && ${myPriceBuy} < ${highestFilteredBuyPrice} && ${dontBuy} == 0 && ${myPriceBuy} != ${highestFilteredBuyPrice}
		{
			priceOne:Set[${highestFilteredBuyPrice}]
			priceTwo:Set[0.01]
			echo Undercutting highest buy order! : ${name} : ${priceOne}
			call modOrderBuy ${db_TypeID} ${priceOne} ${priceTwo} ${myPriceBuy}
		}
		elseif  ${Math.Calc[(${nextHighestFilteredBuyPrice} / ${nextLowestFilteredSellPrice})]} >= ${db_BuyMargin} && ${margin} < ${db_BuyMargin}
		{
			priceOne:Set[${Math.Calc[${nextHighestFilteredBuyPrice} / 1.065]}]
			priceTwo:Set[0.01]
			echo Undercutting next highest buy order! : ${name} : ${priceOne} Margin is trash!
			call modOrderBuy ${db_TypeID} ${priceOne} ${priceTwo} ${myPriceBuy}
		}
		elseif ${myPriceBuy} >= ${highestFilteredBuyPrice}
		{
			echo ===I have the Highest Buy Price!===
		}
		else
		{
			echo Modify Buy Order Margins not met!
		}

	}
	elseif ${dontBuy} == 1 && ${cantModBuy} != 1 && ${theOrderBuyID} != ${myBuyID} && ${myPriceBuy} != 0
	{
		priceOne:Set[${BuyModNum}]
		priceTwo:Set[0.00]
		echo Setting Dynamic Prices! : ${name} : ${priceOne} Market Bubble!
		call modOrderBuy ${db_TypeID} ${priceOne} ${priceTwo} ${myPriceBuy}
	}
	else
	echo == I have the highest Buy Price ====

	echo Sell Order Lowest is ${lowestFilteredSellPrice} next lowest is ${nextLowestFilteredSellPrice}

	if ${myPriceSell} != 0 && ${cantModSell} != 1 && ${theOrderSellID} != ${mySellID} && ${dontSell} != 1
	{

		if ${dontSell} == -1
		{
			priceOne:Set[${nextLowestFilteredSellPrice}]
			priceTwo:Set[0.01]
			echo Undercutting next lowest sell order! : ${name} : ${priceOne} Margins Between!
			call modOrderSell ${db_TypeID} ${priceOne} ${priceTwo} ${myPriceSell}
			return
		}
		elseif  ${Math.Calc[(${nextHighestFilteredBuyPrice} / ${nextLowestFilteredSellPrice})]} > ${db_SellMargin} && ${margin} >= ${db_SellMargin} && ${myPriceSell} >= ${lowestFilteredSellPrice} && ${dontSell} == 0 && ${myPriceSell} != ${lowestFilteredSellPrice}
		{
			priceOne:Set[${lowestFilteredSellPrice}]
			priceTwo:Set[0.01]
			echo Undercutting lowest sell order! : ${name} : ${priceOne}
			call modOrderSell ${db_TypeID} ${priceOne} ${priceTwo} ${myPriceSell}
			return
		}
		elseif  ${Math.Calc[(${nextHighestFilteredBuyPrice} / ${nextLowestFilteredSellPrice})]} > ${db_SellMargin} && ${margin} < ${db_SellMargin}
		{
			priceOne:Set[${Math.Calc[${nextLowestFilteredSellPrice} * 1.065]}]
			priceTwo:Set[0.01]
			echo Undercutting next lowest sell order! : ${name} : ${priceOne} Margin is Trash!
			call modOrderSell ${db_TypeID} ${priceOne} ${priceTwo} ${myPriceSell}
		}
		elseif ${myPriceSell} <= ${lowestFilteredSellPrice}
		{
			echo ===I have the Lowest Sell Price===
		}
		else
		{
			echo Modify Sell Order Margins not met!
		}
	}
	elseif ${dontSell} == 1 && ${cantModSell} != 1 && ${theOrderSellID} != ${mySellID} && ${myPriceSell} != 0
	{
		priceOne:Set[${SellModNum}]
		priceTwo:Set[0.01]
		echo Setting Dynamic Prices! : ${name} : ${priceOne} Market Bubble!
		call modOrderSell ${db_TypeID} ${priceOne} ${priceTwo} ${myPriceSell}
		return
	}
	else
	echo === I have the lowest sell price ===

}

;****************************************************************************************************************************************************************************************************************************************************

function mine(int db_TypeID, float64 db_BuyOrderQuan, float64 db_SellOrderQuan, float64 db_Stock, float64 db_Buy_Margin, float64 db_Sell_Margin)
{

	variable iterator OrderIterator
	variable int OrdersCount

	variable index:myorder MyOrders

	variable index:item HangarItems
	variable index:item HangarShips

	variable iterator HangarIterator

	Me.Station:GetHangarShips[HangarShips,"db_TypeID"]
	Me.Station:GetHangarItems[HangarItems,"db_TypeID"]

	variable int HangarShipsCount
	variable int HangarItemsCount

	HangarItemsCount:Set[${HangarItems.Used}]
	HangarShipsCount:Set[${HangarShips.Used}]

	variable float64 myOrderBuyMinimum
	variable float64 myOrderSellMinimum

	variable float64 MyBuyPrice = 0
	variable float64 MySellPrice = 0

	variable int i = 1

	variable int haveOrderSell = 0
	variable int haveOrderBuy = 0

	variable int64 myBuyID = 0
	variable int64 mySellID = 0

	variable int haveOrderSellTimeOut = 0
	variable int haveOrderBuyTimeOut = 0


	variable int HangarStockRemaining = 0
	variable int assetValueSellRemaining = 0
	variable float64 assetValueS = 0
	variable float64 assetValueB = 0

	variable string SetName = ""
	variable settingsetref thisSet
	thisSet:Set[${LavishSettings[DataTrackerSettings].FindSet[${SetName}]}]
	variable filepath DATA_PATH = "${Script.CurrentDirectory}"
	variable string DATA_FILE = "Data_Tracker.xml"

	SetName:Set["Modifies"]
	thisSet:Set[${LavishSettings[DataTrackerSettings].FindSet[${SetName}]}]

	variable int timeDay = ${Time.Timestamp}

	HangarShips:GetIterator[HangarIterator]

	do
	{
		if ${HangarIterator.Value.TypeID} == ${db_TypeID}
		HangarStockRemaining:Set[${HangarIterator.Value.Quantity}]
	}
	while ${HangarIterator:Next(exists)}

	HangarItems:GetIterator[HangarIterator]

	do
	{
		if ${HangarIterator.Value.TypeID} == ${db_TypeID}
		HangarStockRemaining:Set[${HangarIterator.Value.Quantity}]
	}
	while ${HangarIterator:Next(exists)}

	if (${timeDay} - ${thisSet.FindSetting[DateTime]}) > 4000 && (${timeDay} - ${thisSet.FindSetting[DateTime]}) <= 4001
	{
		LavishSettings[DataTrackerSettings].FindSet[${SetName}]:AddSetting[DateTime,${Time.Timestamp}]
		LavishSettings[DataTrackerSettings].FindSet[${SetName}]:AddSetting[Modifications,0]
		LavishSettings[DataTrackerSettings]:Export[${DATA_FILE}]
		echo Detected Fresh Start, Clearing info!
	}

	if ${thisSet.FindSetting[DateTime]} < (${timeDay} - 3600) && ${thisSet.FindSetting[Modifications]} != 0
	{
		echo Updating Modification Timestamp, theres been ${thisSet.FindSetting[Modifications]} modification(s)!
		LavishSettings[DataTrackerSettings].FindSet[${SetName}]:AddSetting[DateTime,${Time.Timestamp}]
		LavishSettings[DataTrackerSettings].FindSet[${SetName}]:AddSetting[Modifications,0]
		LavishSettings[DataTrackerSettings]:Export[${DATA_FILE}]
	}

	MyOrders:Clear

	EVE:ClearMarketOrderCache
	Me:UpdateMyOrders

	i:Set[1]

	do
	{
		Me:GetMyOrders[MyOrders]
		wait 10
		if ${i} > 5
		break
		i:Inc
	}
	while !${MyOrders.Used}

	i:Set[1]

	MyOrders:GetIterator[OrderIterator]

	SetName:Set[${db_TypeID}]
	thisSet:Set[${LavishSettings[DataTrackerSettings].FindSet[${SetName}]}]

	if ${OrderIterator:First(exists)}
	do
	{
		if ((${OrderIterator.Value.IsBuyOrder}) && (${OrderIterator.Value.TypeID} == ${db_TypeID}))
		{
			echo Buy  Order: ${OrderIterator.Value.Name} :Price: ${OrderIterator.Value.Price} :Initial: ${OrderIterator.Value.InitialQuantity} :Remaining: ${OrderIterator.Value.QuantityRemaining} :Stock: ${HangarStockRemaining}
			myOrderBuyMinimum:Set[${Math.Calc[${OrderIterator.Value.InitialQuantity} * 0.10]}]
			if (${thisSet.FindSetting[CurrentBuyPrice]} == 0)
			LavishSettings[DataTrackerSettings].FindSet[${SetName}]:AddSetting[CurrentBuyPrice,${OrderIterator.Value.Price}]
			if (${thisSet.FindSetting[CurrentBuyPrice]} != ${OrderIterator.Value.Price})
			LavishSettings[DataTrackerSettings].FindSet[${SetName}]:AddSetting[CurrentBuyPrice,${OrderIterator.Value.Price}]
			if (${thisSet.FindSetting[CurrentBuyID]} == 0)
			LavishSettings[DataTrackerSettings].FindSet[${SetName}]:AddSetting[CurrentBuyID,${OrderIterator.Value.ID}]
			if (${OrderIterator.Value.ID} != ${thisSet.FindSetting[CurrentBuyID]})
			{
				LavishSettings[DataTrackerSettings].FindSet[${SetName}]:AddSetting[LastBuyID,${OrderIterator.Value.ID}]
				LavishSettings[DataTrackerSettings].FindSet[${SetName}]:AddSetting[LastBuyPrice,${OrderIterator.Value.Price}]
				LavishSettings[DataTrackerSettings].FindSet[${SetName}]:AddSetting[LastBuyTime,${Time.Timestamp}]
				LavishSettings[DataTrackerSettings].FindSet[${SetName}]:AddSetting[TotalBought,${Math.Calc[(${thisSet.FindSetting[CurrentBuyPrice]} * ${assetValueSellRemaining}) + (${thisSet.FindSetting[CurrentBuyPrice]} * ${HangarStockRemaining})]}]
				LavishSettings[DataTrackerSettings].FindSet[${SetName}]:AddSetting[FilledBuyOrderCount,${Math.Calc[${thisSet.FindSetting[FilledBuyOrderCount]} + 1]}]
			}
			LavishSettings[DataTrackerSettings]:Export[${DATA_FILE}]
		}
		if ((${OrderIterator.Value.IsSellOrder}) && (${OrderIterator.Value.TypeID} == ${db_TypeID}))
		{
			echo Sell Order: ${OrderIterator.Value.Name} :Price: ${OrderIterator.Value.Price} :Initial: ${OrderIterator.Value.InitialQuantity} :Remaining: ${OrderIterator.Value.QuantityRemaining} :Stock: ${HangarStockRemaining}
			assetValueSellRemaining:Set[${OrderIterator.Value.QuantityRemaining}]
			myOrderSellMinimum:Set[${Math.Calc[${OrderIterator.Value.InitialQuantity} * 0.10]}]
			if (${thisSet.FindSetting[CurrentSellPrice]} == 0)
			LavishSettings[DataTrackerSettings].FindSet[${SetName}]:AddSetting[CurrentSellPrice,${OrderIterator.Value.Price}]
			if (${thisSet.FindSetting[CurrentSellPrice]} != ${OrderIterator.Value.Price})
			LavishSettings[DataTrackerSettings].FindSet[${SetName}]:AddSetting[CurrentSellPrice,${OrderIterator.Value.Price}]
			if (${thisSet.FindSetting[CurrentSellID]} == 0)
			LavishSettings[DataTrackerSettings].FindSet[${SetName}]:AddSetting[CurrentSellID,${OrderIterator.Value.ID}]
			if (${OrderIterator.Value.ID} != ${thisSet.FindSetting[CurrentSellID]})
			{
				LavishSettings[DataTrackerSettings].FindSet[${SetName}]:AddSetting[LastSellID,${OrderIterator.Value.ID}]
				LavishSettings[DataTrackerSettings].FindSet[${SetName}]:AddSetting[LastSellPrice,${OrderIterator.Value.Price}]
				LavishSettings[DataTrackerSettings].FindSet[${SetName}]:AddSetting[LastSellTime,${Time.Timestamp}]
				LavishSettings[DataTrackerSettings].FindSet[${SetName}]:AddSetting[TotalSold,${Math.Calc[(${thisSet.FindSetting[CurrentSellPrice]} * ${assetValueSellRemaining}) + (${thisSet.FindSetting[CurrentSellPrice]} * ${HangarStockRemaining})]}]
				LavishSettings[DataTrackerSettings].FindSet[${SetName}]:AddSetting[FilledSellOrderCount,${Math.Calc[${thisSet.FindSetting[FilledSellOrderCount]} + 1]}]
			}
			LavishSettings[DataTrackerSettings]:Export[${DATA_FILE}]
		}
		if (${OrderIterator.Value.TypeID} == ${db_TypeID})
		{
			if (${OrderIterator.Value.IsSellOrder})
			{
				if (${OrderIterator.Value.TypeID} == ${db_TypeID})
				{
					haveOrderSell:Set[1]
				}
			}
			if (${OrderIterator.Value.IsBuyOrder})
			{
				if (${OrderIterator.Value.TypeID} == ${db_TypeID})
				{
					haveOrderBuy:Set[1]
				}
			}
			if (${SellOrdersTimeStamp.Element[${OrderIterator.Value.TypeID}](exists)})
			{
				if (${Time.Timestamp} >= ${Math.Calc[${SellOrdersTimeStamp.Element[${OrderIterator.Value.TypeID}]} + 301]}) && ( ${hadOrderSell} != 1)
				{
					if (${OrderIterator.Value.IsSellOrder})
					{
						if (${OrderIterator.Value.TypeID} == ${db_TypeID})
						{
							haveOrderSellTimeOut:Set[0]
							MySellPrice:Set[${OrderIterator.Value.Price}]
							MySellID:Set[${OrderIterator.Value.ID}]
						}
					}
				}
				else
				{
					haveOrderSellTimeOut:Set[1]
					;echo Timeout Remaining On Sell Order: ${OrderIterator.Value.Name} ::Price:: ${OrderIterator.Value.Price} ::Initial Quantity:: ${OrderIterator.Value.InitialQuantity} ::Quantity Remaining:: ${OrderIterator.Value.QuantityRemaining} ::Stock:: ${db_Stock}
				}
			}
			else
			{
				if (${OrderIterator.Value.IsSellOrder})
				{
					if (${OrderIterator.Value.TypeID} == ${db_TypeID})
					{
						haveOrderSellTimeOut:Set[0]
						MySellPrice:Set[${OrderIterator.Value.Price}]
						MySellID:Set[${OrderIterator.Value.ID}]
					}
				}
			}
			if (${BuyOrdersTimeStamp.Element[${OrderIterator.Value.TypeID}](exists)})
			{
				if (${Time.Timestamp} >= ${Math.Calc[${BuyOrdersTimeStamp.Element[${OrderIterator.Value.TypeID}]} + 301]}) && ( ${hadOrderBuy} != 1)
				{
					if (${OrderIterator.Value.IsBuyOrder})
					{
						if (${OrderIterator.Value.TypeID} == ${db_TypeID})
						{
							haveOrderBuyTimeOut:Set[0]
							MyBuyPrice:Set[${OrderIterator.Value.Price}]
							MyBuyID:Set[${OrderIterator.Value.ID}]
						}
					}
				}
				else
				{
					haveOrderBuyTimeOut:Set[1]
					;echo Timeout Remaining On Buy Order: ${OrderIterator.Value.Name} ::Price:: ${OrderIterator.Value.Price} ::Initial Quantity:: ${OrderIterator.Value.InitialQuantity} ::Quantity Remaining:: ${OrderIterator.Value.QuantityRemaining} ::Stock:: ${db_Stock}
				}
			}
			else
			{
				if (${OrderIterator.Value.IsBuyOrder})
				{
					if (${OrderIterator.Value.TypeID} == ${db_TypeID})
					{
						haveOrderBuyTimeOut:Set[0]
						MyBuyPrice:Set[${OrderIterator.Value.Price}]
						MyBuyID:Set[${OrderIterator.Value.ID}]
					}
				}
			}
		}
	}
	while ${OrderIterator:Next(exists)}

	i:Set[1]

	if ((${haveOrderBuy} == 1) || (${haveOrderSell} == 1))
	{
		call updateIDbuySell ${db_TypeID} ${MyBuyPrice} ${MySellPrice} ${db_Buy_Margin} ${db_Sell_Margin} ${MyBuyID} ${MySellID} ${haveOrderBuyTimeOut} ${haveOrderSellTimeOut} ${myOrderBuyMinimum} ${myOrderSellMinimum}
	}

	if (${haveOrderBuy} == 0) && (${haveOrderBuyNoTimeOutRemains} != 1) && ( ${hadOrderBuy} != 1)
	{
		hadOrderBuy:Set[0]
		call stockBuy ${db_TypeID} ${db_BuyOrderQuan} ${db_Stock} ${MyBuyID} ${MySellID} ${db_Buy_Margin} ${myOrderBuyMinimum} ${myOrderSellMinimum}
		if ${hadOrderBuy} == 1
		call mine ${db_TypeID} ${db_BuyOrderQuan} ${db_SellOrderQuan} ${db_Stock} ${db_Buy_Margin} ${db_Sell_Margin}
	}
	if (${haveOrderSell} == 0) && (${haveOrderSellNoTimeOutRemains} != 1) && ( ${hadOrderSell} != 1)
	{
		hadOrderSell:Set[0]
		call stockSell ${db_TypeID} ${db_SellOrderQuan} ${db_Stock} ${MyBuyID} ${MySellID} ${db_Sell_Margin} ${myOrderBuyMinimum} ${myOrderSellMinimum}
		if ${hadOrderSell} == 1
		call mine ${db_TypeID} ${db_BuyOrderQuan} ${db_SellOrderQuan} ${db_Stock} ${db_Buy_Margin} ${db_Sell_Margin}
	}

	ActiveBuyPrice:Set[${Math.Calc[(${thisSet.FindSetting[CurrentBuyPrice]} * ${assetValueSellRemaining}) + (${thisSet.FindSetting[CurrentBuyPrice]} * ${HangarStockRemaining})]}]

	ActiveSellPrice:Set[${Math.Calc[(${thisSet.FindSetting[CurrentSellPrice]} * ${assetValueSellRemaining}) + (${thisSet.FindSetting[CurrentSellPrice]} * ${HangarStockRemaining})]}]

	assetValueS:Set[${Math.Calc[(${thisSet.FindSetting[LastSellPrice]} * ${assetValueSellRemaining}) + (${thisSet.FindSetting[LastSellPrice]} * ${HangarStockRemaining})]}]

	assetValueB:Set[${Math.Calc[(${thisSet.FindSetting[LastBuyPrice]} * ${assetValueSellRemaining}) + (${thisSet.FindSetting[LastBuyPrice]} * ${HangarStockRemaining})]}]

	totalAssetValueB:Set[${Math.Calc[(${assetValueB} + ${totalAssetValueB})]}]

	totalAssetValueS:Set[${Math.Calc[(${assetValueS} + ${totalAssetValueS})]}]

	iskMade:Set[${Math.Calc[(${totalAssetValueS} - ${totalAssetValueB}]}]

	hadOrderBuy:Set[0]
	hadOrderSell:Set[0]
}

;****************************************************************************************************************************************************************************************************************************************************

function putInBuyOrder(int db_TypeID, float64 db_BuyOrderQuan, float64 db_Stock, int64 myBuyID, int64 mySellID, float64 db_BuyMargin, float64 myOrderBuyMinimum, float64 myOrderSellMinimum)
{
	variable iterator MyOrderIterator
	variable index:myorder MyOrders
	variable int MyOrdersCount

	variable iterator OrderIterator
	variable int OrdersCount

	variable index:marketorder buyOrders
	variable index:marketorder sellOrders

	variable index:int TypeIDs
	variable index:string TypeNames

	variable int Station = ${Me.StationID}

	variable string name = ""

	variable int i = 1

	variable float64 BuyModNum = 0
	variable float64 SellModNum = 0

	variable int dontBuy = 0
	variable int dontSell = 0

	variable float64 modifiedFilteredBuyPriceMargin = 0
	variable float64 modifiedFilteredSellPriceMargin = 0
	variable float64 filteredBuyPriceMargin = 0
	variable float64 filteredSellPriceMargin = 0

	variable float64 numberOfActiveBuyOrders = 0
	variable float64 numberOfActiveSellOrders = 0

	variable float64 highestFilteredBuyPrice = 0
	variable float64 lowestFilteredSellPrice = 1000000000000000000
	variable float64 nextLowestFilteredSellPrice = 2000000000000000000
	variable float64 nextHighestFilteredBuyPrice = 0

	variable float64 margin = 0
	variable float64 compar = 0

	variable float64 priceOne = 0
	variable float64 priceTwo = 0

	variable string SetName = ""
	variable settingsetref thisSet
	variable filepath DATA_PATH = "${Script.CurrentDirectory}"
	variable string DATA_FILE = "Data_Tracker.xml"
	SetName:Set[${db_TypeID}]
	thisSet:Set[${LavishSettings[DataTrackerSettings].FindSet[${SetName}]}]

	Orders:Clear
	EVE:ClearMarketOrderCache
	EVE:FetchMarketOrders[${db_TypeID}]

	i:Set[1]

	do
	{
		EVE:GetMarketOrders[buyOrders, ${db_TypeID},"Buy"]
		wait 10
		if ${i} > 5
		break
		i:Inc
	}
	while !${buyOrders.Used}

	i:Set[1]

	do
	{
		EVE:GetMarketOrders[sellOrders, ${db_TypeID},"Sell"]
		wait 10
		if ${i} > 5
		break
		i:Inc
	}
	while !${sellOrders.Used}

	IndexName:Set["buyOrders"]

	i:Set[1]

	while ${i} <= ${${IndexName}.Used}
	{
		if ( ${i} == 1 ) || ${${IndexName}[${Math.Calc[${i}-1]}].${MemberName}} >= ${${IndexName}[${i}].${MemberName}}
		{
			i:Inc
		}
		else
		{
			${IndexName}:Swap[${i}, ${Math.Calc[${i}-1]}]
			i:Dec
		}
	}

	buyOrders:GetIterator[OrderIterator]

	if ${OrderIterator:First(exists)}
	do
	{
		if ${OrderIterator.Value.IsBuyOrder}
		{
			if ${OrderIterator.Value.StationID} == ${Station}
			{
				if ${OrderIterator.Value.Price} > ${highestFilteredBuyPrice} && ${OrderIterator.Value.ID} != ${myBuyID} && ${OrderIterator.Value.QuantityRemaining} >= ${myOrderBuyMinimum} && ${OrderIterator.Value.QuantityRemaining} >= ${myOrderSellMinimum}
				{
					name:Set[${OrderIterator.Value.Name}]
					highestFilteredBuyPrice:Set[${OrderIterator.Value.Price}]
					theOrderBuyID:Set[${OrderIterator.Value.ID}]
				}
				if ${OrderIterator.Value.Price} < ${highestFilteredBuyPrice} && ${OrderIterator.Value.ID} != ${myBuyID} && ${OrderIterator.Value.QuantityRemaining} >= ${myOrderBuyMinimum} && ${OrderIterator.Value.QuantityRemaining} >= ${myOrderSellMinimum} && ${OrderIterator.Value.Price} > ${nextHighestFilteredBuyPrice}
				{
					nextHighestFilteredBuyPrice:Set[${OrderIterator.Value.Price}]
				}
			}
		}
	}
	while ${OrderIterator:Next(exists)}

	i:Set[1]

	IndexName:Set["sellOrders"]

	while ${i} <= ${${IndexName}.Used}
	{
		if ( ${i} == 1 ) || ${${IndexName}[${Math.Calc[${i}-1]}].${MemberName}} <= ${${IndexName}[${i}].${MemberName}}
		{
			i:Inc
		}
		else
		{
			${IndexName}:Swap[${i}, ${Math.Calc[${i}-1]}]
			i:Dec
		}
	}

	sellOrders:GetIterator[OrderIterator]

	if ${OrderIterator:First(exists)}
	do
	{
		if ${OrderIterator.Value.IsSellOrder}
		{
			if ${OrderIterator.Value.StationID} == ${Station}
			{
				if ${OrderIterator.Value.Price} < ${lowestFilteredSellPrice} && ${OrderIterator.Value.ID} != ${mySellID} && ${OrderIterator.Value.QuantityRemaining} >= ${myOrderSellMinimum} && ${OrderIterator.Value.QuantityRemaining} >= ${myOrderBuyMinimum}
				{
					lowestFilteredSellPrice:Set[${OrderIterator.Value.Price}]
					theOrderSellID:Set[${OrderIterator.Value.ID}]
				}
				if ${OrderIterator.Value.Price} > ${lowestFilteredSellPrice} && ${OrderIterator.Value.ID} != ${mySellID} && ${OrderIterator.Value.QuantityRemaining} >= ${myOrderSellMinimum} && ${OrderIterator.Value.QuantityRemaining} >= ${myOrderBuyMinimum} && ${OrderIterator.Value.Price} < ${nextLowestFilteredSellPrice}
				{
					nextLowestFilteredSellPrice:Set[${OrderIterator.Value.Price}]
				}
			}
		}
	}
	while ${OrderIterator:Next(exists)}

	if (${sellOrders.Used} < 6) || (${buyOrders.Used} < 6)
	{
		echo Skipping this item becasue there are not enough orders on the market Error buy ${buyOrders.Used}  :: Error Sell : ${sellOrders.Used}
		return
	}

	if ${highestFilteredBuyPrice} < 10 || ${lowestFilteredSellPrice} < 10
	{
		echo Prices Less than 10.00 ISK Stopping trading!
		return
	}

	if (${buyOrders.Used} < 6) || (${sellOrders.Used} < 6)
	{
		echo Skipping this item becasue there are not enough orders on the market Error buy ${buyOrders.Used}  :: Error Sell : ${sellOrders.Used}
		return
	}

	if ${highestFilteredBuyPrice} < 10 || ${lowestFilteredSellPrice} < 10
	{
		echo Prices Less than 10.00 ISK Stopping trading!
		return
	}

	filteredBuyPriceMargin:Set[${Math.Calc[(${highestFilteredBuyPrice} / ${nextHighestFilteredBuyPrice})]}]
	filteredSellPriceMargin:Set[${Math.Calc[(${nextLowestFilteredSellPrice} / ${lowestFilteredSellPrice})]}]
	modifiedFilteredBuyPriceMargin:Set[${Math.Calc[((((${highestFilteredBuyPrice} / ${nextHighestFilteredBuyPrice}) + ${filteredSellPriceMargin}) * 0.0005))]}]
	modifiedFilteredSellPriceMargin:Set[${Math.Calc[((((${nextLowestFilteredSellPrice} / ${lowestFilteredSellPrice}) + ${filteredBuyPriceMargin}) * 0.0005))]}]
	modifiedFilteredBuyPriceMargin:Set[${Math.Calc[(${filteredSellPriceMargin} + ${modifiedFilteredBuyPriceMargin})]}]
	modifiedFilteredSellPriceMargin:Set[${Math.Calc[(${filteredBuyPriceMargin} + ${modifiedFilteredSellPriceMargin})]}]

	if ${filteredBuyPriceMargin} > ${modifiedFilteredBuyPriceMargin}
	{
		echo Inner buy margins on item ${name} not met. This means theres a large margin in the item with a buy order filling the gap. Modding Order Buy.
		echo ${filteredBuyPriceMargin} should be greater than ${modifiedFilteredBuyPriceMargin}
		dontBuy:Set[-1]
	}

	if ${filteredSellPriceMargin} > ${modifiedFilteredSellPriceMargin}
	{
		echo Inner sell margins on item ${name} not met. This means theres a large margin in the item with a sell order filling the gap. Modding Order Sell.
		echo ${filteredSellPriceMargin} should be greater than ${modifiedFilteredSellPriceMargin}
		dontSell:Set[-1]
	}

	if ${highestFilteredBuyPrice} > ${thisSet.FindSetting[LastSellPrice]} && (${Time.Timestamp} < (${Math.Calc[${thisSet.FindSetting[LastBuyTime]}]} + 38800)) && (${thisSet.FindSetting[LastSellPrice]} != 0)
	{
		BuyModNum:Set[${Math.Calc[${thisSet.FindSetting[LastBuyPrice]} / 1.03]}]
		echo OOPS! Market bubble! Changing buy trading for item ${name} setting price to ${BuyModNum}
		dontBuy:Set[1]
	}

	if ${lowestFilteredSellPrice} < ${thisSet.FindSetting[LastBuyPrice]}  && (${Time.Timestamp} < (${Math.Calc[${thisSet.FindSetting[LastSellTime]}]} + 38800)) && (${thisSet.FindSetting[LastBuyPrice]} != 0)
	{
		SellModNum:Set[${Math.Calc[${thisSet.FindSetting[LastSellPrice]} * 1.03]}]
		echo OOPS! Market Bubble! Changing Sell trading for item ${name} setting price to ${SellModNum}
		dontSell:Set[1]
	}

	margin:Set[${Math.Calc[(${lowestFilteredSellPrice} / ${highestFilteredBuyPrice})]}]
	compar:Set[${Math.Calc[(${lowestFilteredSellPrice} - ${highestFilteredBuyPrice})]}]

	if (${compar} <= 0 )
	{
		echo Error Negative Comparison!!!
		return
	}

	if (${highestFilteredBuyPrice} >= ${lowestFilteredSellPrice})
	{
		echo Negative Comparison!!!
		return
	}

	if ${highestFilteredBuyPrice} <= 10 ||  ${nextHighestFilteredBuyPrice} <= 10
	{
		echo Error Buy price too low!
		return
	}

	if ${dontBuy} == 1
	{
		echo Placing a buy order dynamically. Price: ${BuyModNum} Quan: ${db_BuyOrderQuan} Market Bubble!
		EVE:PlaceBuyOrder[${Station}, ${db_TypeID}, ${BuyModNum}, ${db_BuyOrderQuan}, "Station", 1, 90]
	}
	elseif ${dontBuy} == -1
	{
		echo Placing buy order at a lower price than the highest buy order. Price: ${nextHighestFilteredBuyPrice}, Quan: ${db_BuyOrderQuan} Margins Between!
		EVE:PlaceBuyOrder[${Station}, ${db_TypeID}, ${nextHighestFilteredBuyPrice}, ${db_BuyOrderQuan}, "Station", 1, 90]
	}
	elseif ${margin} >= ${db_BuyMargin} && ${Math.Calc[(${nextHighestFilteredBuyPrice} / ${nextLowestFilteredSellPrice})]} > ${db_BuyMargin} && ${dontBuy} == 0
	{
		echo Placing normal buy order. Price: ${highestFilteredBuyPrice} Quan: ${db_BuyOrderQuan}
		EVE:PlaceBuyOrder[${Station}, ${db_TypeID}, ${highestFilteredBuyPrice}, ${db_BuyOrderQuan}, "Station", 1, 90]
	}
	elseif (${Math.Calc[(${nextHighestFilteredBuyPrice} / ${nextLowestFilteredSellPrice})]}) >= ${db_BuyMargin} && ${margin} < ${db_BuyMargin}
	{
		echo Placing buy order at a lower price than the highest buy order. Price: ${nextHighestFilteredBuyPrice}, Quan: ${db_BuyOrderQuan} Margin is trash!
		EVE:PlaceBuyOrder[${Station}, ${db_TypeID}, ${Math.Calc[${nextHighestFilteredBuyPrice} / 1.065]}, ${db_BuyOrderQuan}, "Station", 1, 90]
	}
	else
	{
		echo Margins not met!
		return
	}

	SetName:Set["Modifies"]
	thisSet:Set[${LavishSettings[DataTrackerSettings].FindSet[${SetName}]}]
	variable int modifies
	modifies:Set[${Math.Calc[${thisSet.FindSetting[Modifications]} + 1]}]
	LavishSettings[DataTrackerSettings].FindSet[${SetName}]:AddSetting[Modifications,${modifies}]
	LavishSettings[DataTrackerSettings]:Export[${DATA_FILE}]
	echo Updating Modification Value, theres been ${modifies} modification(s)!

	wait 100

	hadOrderBuy:Set[1]

	MyOrders:Clear

	EVE:ClearMarketOrderCache
	Me:UpdateMyOrders

	i:Set[1]

	do
	{
		Me:GetMyOrders[MyOrders]
		wait 10
		if ${i} > 5
		break
		i:Inc
	}
	while !${MyOrders.Used}

	i:Set[1]

	MyOrders:GetIterator[MyOrderIterator]

	if ${MyOrderIterator:First(exists)}
	do
	{
		if (${MyOrderIterator.Value.IsBuyOrder})
		{
			if (${MyOrderIterator.Value.TypeID} == ${db_TypeID})
			{
				BuyOrdersTimeStamp:Set[${MyOrderIterator.Value.TypeID},${Time.Timestamp}]
				return
			}
		}
	}
	while ${MyOrderIterator:Next(exists)}
	return
}

;****************************************************************************************************************************************************************************************************************************************************

function putInSellOrder(int db_TypeID, int db_SellOrderQuan, float64 db_Stock, int64 myBuyID, int64 mySellID, float64 db_SellMargin, float64 myOrderBuyMinimum, float64 myOrderSellMinimum)
{
	variable iterator MyOrderIterator
	variable index:myorder MyOrders
	variable int MyOrdersCount

	variable index:item HangarItems
	variable index:item HangarShips

	variable iterator HangarIterator

	variable int HangarShipsCount
	variable int HangarItemsCount

	Me.Station:GetHangarShips[HangarShips,"db_TypeID"]
	Me.Station:GetHangarItems[HangarItems,"db_TypeID"]

	HangarItemsCount:Set[${HangarItems.Used}]
	HangarShipsCount:Set[${HangarShips.Used}]

	variable iterator OrderIterator
	variable int OrdersCount

	variable index:marketorder buyOrders
	variable index:marketorder sellOrders

	variable index:int TypeIDs
	variable index:string TypeNames

	variable int Station = ${Me.StationID}

	variable string name = ""

	variable int i = 1

	variable float64 BuyModNum = 0
	variable float64 SellModNum = 0

	variable int dontBuy = 0
	variable int dontSell = 0

	variable float64 modifiedFilteredBuyPriceMargin = 0
	variable float64 modifiedFilteredSellPriceMargin = 0
	variable float64 filteredBuyPriceMargin = 0
	variable float64 filteredSellPriceMargin = 0

	variable float64 numberOfActiveBuyOrders = 0
	variable float64 numberOfActiveSellOrders = 0

	variable float64 highestFilteredBuyPrice = 0
	variable float64 lowestFilteredSellPrice = 1000000000000000000
	variable float64 nextLowestFilteredSellPrice = 2000000000000000000
	variable float64 nextHighestFilteredBuyPrice = 0

	variable float64 margin = 0
	variable float64 compar = 0

	variable float64 priceOne = 0
	variable float64 priceTwo = 0

	variable string SetName = ""
	variable settingsetref thisSet
	variable filepath DATA_PATH = "${Script.CurrentDirectory}"
	variable string DATA_FILE = "Data_Tracker.xml"
	SetName:Set[${db_TypeID}]
	thisSet:Set[${LavishSettings[DataTrackerSettings].FindSet[${SetName}]}]


	Orders:Clear
	EVE:ClearMarketOrderCache
	EVE:FetchMarketOrders[${db_TypeID}]

	i:Set[1]

	do
	{
		EVE:GetMarketOrders[buyOrders, ${db_TypeID},"Buy"]
		wait 10
		if ${i} > 5
		break
		i:Inc
	}
	while !${buyOrders.Used}

	i:Set[1]

	do
	{
		EVE:GetMarketOrders[sellOrders, ${db_TypeID},"Sell"]
		wait 10
		if ${i} > 5
		break
		i:Inc
	}
	while !${sellOrders.Used}

	IndexName:Set["buyOrders"]

	i:Set[1]

	while ${i} <= ${${IndexName}.Used}
	{
		if ( ${i} == 1 ) || ${${IndexName}[${Math.Calc[${i}-1]}].${MemberName}} >= ${${IndexName}[${i}].${MemberName}}
		{
			i:Inc
		}
		else
		{
			${IndexName}:Swap[${i}, ${Math.Calc[${i}-1]}]
			i:Dec
		}
	}

	buyOrders:GetIterator[OrderIterator]

	if ${OrderIterator:First(exists)}
	do
	{
		if ${OrderIterator.Value.IsBuyOrder}
		{
			if ${OrderIterator.Value.StationID} == ${Station}
			{
				if ${OrderIterator.Value.Price} > ${highestFilteredBuyPrice} && ${OrderIterator.Value.ID} != ${myBuyID} && ${OrderIterator.Value.QuantityRemaining} >= ${myOrderBuyMinimum} && ${OrderIterator.Value.QuantityRemaining} >= ${myOrderSellMinimum}
				{
					name:Set[${OrderIterator.Value.Name}]
					highestFilteredBuyPrice:Set[${OrderIterator.Value.Price}]
					theOrderBuyID:Set[${OrderIterator.Value.ID}]
				}
				if ${OrderIterator.Value.Price} < ${highestFilteredBuyPrice} && ${OrderIterator.Value.ID} != ${myBuyID} && ${OrderIterator.Value.QuantityRemaining} >= ${myOrderBuyMinimum} && ${OrderIterator.Value.QuantityRemaining} >= ${myOrderSellMinimum} && ${OrderIterator.Value.Price} > ${nextHighestFilteredBuyPrice}
				{
					nextHighestFilteredBuyPrice:Set[${OrderIterator.Value.Price}]
				}
			}
		}
	}
	while ${OrderIterator:Next(exists)}

	i:Set[1]

	IndexName:Set["sellOrders"]

	while ${i} <= ${${IndexName}.Used}
	{
		if ( ${i} == 1 ) || ${${IndexName}[${Math.Calc[${i}-1]}].${MemberName}} <= ${${IndexName}[${i}].${MemberName}}
		{
			i:Inc
		}
		else
		{
			${IndexName}:Swap[${i}, ${Math.Calc[${i}-1]}]
			i:Dec
		}
	}

	sellOrders:GetIterator[OrderIterator]

	if ${OrderIterator:First(exists)}
	do
	{
		if ${OrderIterator.Value.IsSellOrder}
		{
			if ${OrderIterator.Value.StationID} == ${Station}
			{
				if ${OrderIterator.Value.Price} < ${lowestFilteredSellPrice} && ${OrderIterator.Value.ID} != ${mySellID} && ${OrderIterator.Value.QuantityRemaining} >= ${myOrderSellMinimum} && ${OrderIterator.Value.QuantityRemaining} >= ${myOrderBuyMinimum}
				{
					lowestFilteredSellPrice:Set[${OrderIterator.Value.Price}]
					theOrderSellID:Set[${OrderIterator.Value.ID}]
				}
				if ${OrderIterator.Value.Price} > ${lowestFilteredSellPrice} && ${OrderIterator.Value.ID} != ${mySellID} && ${OrderIterator.Value.QuantityRemaining} >= ${myOrderSellMinimum} && ${OrderIterator.Value.QuantityRemaining} >= ${myOrderBuyMinimum} && ${OrderIterator.Value.Price} < ${nextLowestFilteredSellPrice}
				{
					nextLowestFilteredSellPrice:Set[${OrderIterator.Value.Price}]
				}
			}
		}
	}
	while ${OrderIterator:Next(exists)}

	if (${sellOrders.Used} < 6) || (${buyOrders.Used} < 6)
	{
		echo Skipping this item becasue there are not enough orders on the market Error buy ${buyOrders.Used}  :: Error Sell : ${sellOrders.Used}
		return
	}

	if ${highestFilteredBuyPrice} < 10 || ${lowestFilteredSellPrice} < 10
	{
		echo Prices Less than 10.00 ISK Stopping trading!
		return
	}

	if ${highestFilteredBuyPrice} < 10 || ${lowestFilteredSellPrice} < 10
	{
		echo Prices Less than 10.00 ISK Stopping trading!
		return
	}

	filteredBuyPriceMargin:Set[${Math.Calc[(${highestFilteredBuyPrice} / ${nextHighestFilteredBuyPrice})]}]
	filteredSellPriceMargin:Set[${Math.Calc[(${nextLowestFilteredSellPrice} / ${lowestFilteredSellPrice})]}]
	modifiedFilteredBuyPriceMargin:Set[${Math.Calc[((((${highestFilteredBuyPrice} / ${nextHighestFilteredBuyPrice}) + ${filteredSellPriceMargin}) * 0.0005))]}]
	modifiedFilteredSellPriceMargin:Set[${Math.Calc[((((${nextLowestFilteredSellPrice} / ${lowestFilteredSellPrice}) + ${filteredBuyPriceMargin}) * 0.0005))]}]
	modifiedFilteredBuyPriceMargin:Set[${Math.Calc[(${filteredSellPriceMargin} + ${modifiedFilteredBuyPriceMargin})]}]
	modifiedFilteredSellPriceMargin:Set[${Math.Calc[(${filteredBuyPriceMargin} + ${modifiedFilteredSellPriceMargin})]}]

	if ${filteredBuyPriceMargin} > ${modifiedFilteredBuyPriceMargin}
	{
		echo The margins between the buy orders of ${name} are too spaced out, modding!
		echo ${filteredBuyPriceMargin} should be greater than ${modifiedFilteredBuyPriceMargin}
		dontBuy:Set[-1]
	}

	if ${filteredSellPriceMargin} > ${modifiedFilteredSellPriceMargin}
	{
		echo The margins between the sell orders of ${name} are too spaced out, modding!
		echo ${filteredSellPriceMargin} should be greater than ${modifiedFilteredSellPriceMargin}
		dontSell:Set[-1]
	}

	if ${highestFilteredBuyPrice} > ${thisSet.FindSetting[LastSellPrice]} && (${Time.Timestamp} < (${Math.Calc[${thisSet.FindSetting[LastBuyTime]}]} + 38800)) && (${thisSet.FindSetting[LastSellPrice]} != 0)
	{
		BuyModNum:Set[${Math.Calc[${thisSet.FindSetting[LastBuyPrice]} / 1.03]}]
		echo OOPS! Market bubble! Changing buy trading for item ${name} setting price to ${BuyModNum}
		dontBuy:Set[1]
	}

	if ${lowestFilteredSellPrice} < ${thisSet.FindSetting[LastBuyPrice]}  && (${Time.Timestamp} < (${Math.Calc[${thisSet.FindSetting[LastSellTime]}]} + 38800)) && (${thisSet.FindSetting[LastBuyPrice]} != 0)
	{
		SellModNum:Set[${Math.Calc[${thisSet.FindSetting[LastSellPrice]} * 1.03]}]
		echo OOPS! Market Bubble! Changing Sell trading for item ${name} setting price to ${SellModNum}
		dontSell:Set[1]
	}

	margin:Set[${Math.Calc[(${lowestFilteredSellPrice} / ${highestFilteredBuyPrice})]}]
	compar:Set[${Math.Calc[(${lowestFilteredSellPrice} - ${highestFilteredBuyPrice})]}]

	if (${compar} <= 0 )
	{
		echo Error Negative Comparison!!!
		return
	}

	if (${highestFilteredBuyPrice} >= ${lowestFilteredSellPrice})
	{
		echo Error Negative Comparison!!!
		return
	}

	if ${lowestFilteredSellPrice} <= 10 ||  ${nextLowestFilteredSellPrice} <= 10
	{
		echo Error Sell price too low!
		return
	}

	i:Set[1]

	HangarItems:GetIterator[HangarIterator]

	do
	{
		if (${HangarIterator.Value.Quantity} >= ${db_SellOrderQuan})
		{
			if (${HangarIterator.Value.TypeID} == ${db_TypeID})
			{
				if ${dontSell} == 1
				{
					echo Placing a sell order dynamically. Price: ${SellModNum} Quan: ${db_SellOrderQuan} Market Bubble!
					HangarIterator.Value:PlaceSellOrder[${SellModNum},${db_SellOrderQuan},90]
				}
				elseif ${dontSell} == -1
				{
					echo Placing sell order at a higher price than lowest sell order. Price: ${nextLowestFilteredSellPrice} Quan: ${db_SellOrderQuan} The margins between!
					HangarIterator.Value:PlaceSellOrder[${nextLowestFilteredSellPrice},${db_SellOrderQuan},90]
					hadOrderSell:Set[1]
				}
				elseif ${margin} > ${db_SellMargin} &&  ${dontSell} == 0
				{
					echo Placing normal sell order. Price: ${lowestFilteredSellPrice} Quan: ${db_SellOrderQuan}
					HangarIterator.Value:PlaceSellOrder[${lowestFilteredSellPrice},${db_SellOrderQuan},90]
					hadOrderSell:Set[1]
				}
				elseif (${Math.Calc[(${nextHighestFilteredBuyPrice} / ${nextLowestFilteredSellPrice})]}) > ${db_SellMargin} && ${margin} < ${db_SellMargin}
				{
					echo Placing sell order at a higher price than lowest sell order. Price: ${nextLowestFilteredSellPrice} Quan: ${db_SellOrderQuan} Margin is trash!
					HangarIterator.Value:PlaceSellOrder[${Math.Calc[${nextLowestFilteredSellPrice} * 1.065]},${db_SellOrderQuan},90]
				}
				else
				{
					echo Margins not met!
					return
				}
			}
		}
	}
	while ${HangarIterator:Next(exists)}

	HangarShips:GetIterator[HangarIterator]

	do
	{
		if (${HangarIterator.Value.Quantity} >= ${db_SellOrderQuan})
		{
			if (${HangarIterator.Value.TypeID} == ${db_TypeID})
			{
				if ${dontSell} == 1
				{
					echo Placing a sell order dynamically. Price: ${SellModNum} Quan: ${db_SellOrderQuan} Market Bubble!
					HangarIterator.Value:PlaceSellOrder[${SellModNum},${db_SellOrderQuan},90]
				}
				elseif ${dontSell} == -1
				{
					echo Placing sell order at a higher price than lowest sell order. Price: ${nextLowestFilteredSellPrice} Quan: ${db_SellOrderQuan} The margins between!
					HangarIterator.Value:PlaceSellOrder[${nextLowestFilteredSellPrice},${db_SellOrderQuan},90]
					hadOrderSell:Set[1]
				}
				elseif ${margin} < ${db_SellMargin} &&  ${dontSell} == 0
				{
					echo Placing normal sell order. Price: ${lowestFilteredSellPrice} Quan: ${db_SellOrderQuan}
					HangarIterator.Value:PlaceSellOrder[${lowestFilteredSellPrice},${db_SellOrderQuan},90]
					hadOrderSell:Set[1]
				}
				elseif (${Math.Calc[(${nextHighestFilteredBuyPrice} / ${nextLowestFilteredSellPrice})]}) > ${db_SellMargin} && ${margin} < ${db_SellMargin}
				{
					echo Placing sell order at a higher price than lowest sell order. Price: ${nextLowestFilteredSellPrice} Quan: ${db_SellOrderQuan} Margin is trash!
					HangarIterator.Value:PlaceSellOrder[${Math.Calc[${nextLowestFilteredSellPrice} * 1.065]},${db_SellOrderQuan},90]
				}
				else
				{
					echo Margins not met!
					return
				}
			}
		}
	}
	while ${HangarIterator:Next(exists)}

	SetName:Set["Modifies"]
	thisSet:Set[${LavishSettings[DataTrackerSettings].FindSet[${SetName}]}]
	variable int modifies
	modifies:Set[${Math.Calc[${thisSet.FindSetting[Modifications]} + 1]}]
	LavishSettings[DataTrackerSettings].FindSet[${SetName}]:AddSetting[Modifications,${modifies}]
	LavishSettings[DataTrackerSettings]:Export[${DATA_FILE}]
	echo Updating Modification Value, theres been ${modifies} modification(s)!

	if ${hadOrderSell} == 1
	{
		wait 100
		MyOrders:Clear

		EVE:ClearMarketOrderCache
		Me:UpdateMyOrders

		i:Set[1]

		do
		{
			Me:GetMyOrders[MyOrders]
			wait 10
			if ${i} > 5
			break
			i:Inc
		}
		while !${MyOrders.Used}

		i:Set[1]

		MyOrders:GetIterator[MyOrderIterator]

		if ${MyOrderIterator:First(exists)}
		do
		{
			if (${MyOrderIterator.Value.IsSellOrder})
			{
				if (${MyOrderIterator.Value.TypeID} == ${db_TypeID})
				{
					SellOrdersTimeStamp:Set[${MyOrderIterator.Value.TypeID},${Time.Timestamp}]
					return
				}
			}
		}
		while ${MyOrderIterator:Next(exists)}
		return
	}
}

;****************************************************************************************************************************************************************************************************************************************************

function stockBuy(int db_TypeID, int db_BuyOrderQuan, float64 db_Stock, int64 MyBuyID, int64 MySellID, float64 db_Buy_Margin, float64 myOrderBuyMinimum, float64 myOrderSellMinimum)
{
	variable int i = 1
	variable int numToBuy = 0
	variable int itExists = 0
	variable index:item HangarItems
	variable index:item HangarShips

	variable iterator HangarIterator

	variable int HangarShipsCount
	variable int HangarItemsCount

	Me.Station:GetHangarShips[HangarShips,"db_TypeID"]
	Me.Station:GetHangarItems[HangarItems,"db_TypeID"]

	HangarItemsCount:Set[${HangarItems.Used}]
	HangarShipsCount:Set[${HangarShips.Used}]

	if (${db_BuyOrderQuan} == 0) || (${db_Stock} <= 0)
	{
		if (${db_BuyOrderQuan} == 0)
		echo Buy order quantity says not to buy anything, not buying anything!
		if (${db_Stock} <= 0)
		echo Stock is set to Zero, not buying anything!
		return
	}

	HangarItems:GetIterator[HangarIterator]

	do
	{
		if (${HangarIterator.Value.TypeID} == ${db_TypeID})
		{
			itExists:Set[1]

			if (${HangarIterator.Value.Quantity} == ${db_Stock})
			{
				return
			}
			if (${HangarIterator.Value.Quantity} < ${db_Stock})
			{
				numToBuy:Set[${Math.Calc[(${db_Stock} - ${HangarIterator.Value.Quantity})]}]
				if (${numToBuy} > ${db_BuyOrderQuan})
				{
					numToBuy:Set[${db_BuyOrderQuan}]
				}
				call putInBuyOrder ${db_TypeID} ${numToBuy} ${db_Stock} ${MyBuyID} ${MySellID} ${db_Buy_Margin} ${myOrderBuyMinimum} ${myOrderSellMinimum}
				return
			}
		}
	}
	while ${HangarIterator:Next(exists)}

	i:Set[1]

	HangarShips:GetIterator[HangarIterator]

	do
	{
		if (${HangarIterator.Value.TypeID} == ${db_TypeID})
		{
			itExists:Set[1]
			if (${HangarIterator.Value.Quantity} == ${db_Stock})
			{
				return
			}
			if (${HangarIterator.Value.Quantity} < ${db_Stock})
			{
				numToBuy:Set[${Math.Calc[(${db_Stock} - ${HangarIterator.Value.Quantity})]}]
				if (${numToBuy} > ${db_BuyOrderQuan})
				{
					numToBuy:Set[${db_BuyOrderQuan}]
				}
				call putInBuyOrder ${db_TypeID} ${numToBuy} ${db_Stock} ${MyBuyID} ${MySellID} ${db_Buy_Margin} ${myOrderBuyMinimum} ${myOrderSellMinimum}
				return
			}
		}
	}
	while ${HangarIterator:Next(exists)}

	if (${itExists} == 0)
	{
		call putInBuyOrder ${db_TypeID} ${db_BuyOrderQuan} ${db_Stock} ${MyBuyID} ${MySellID} ${db_Buy_Margin} ${myOrderBuyMinimum} ${myOrderSellMinimum}
	}
}

;****************************************************************************************************************************************************************************************************************************************************

function stockSell(int db_TypeID, float64 db_SellOrderQuan, float64 db_Stock, int64 myBuyID, int64 mySellID, float64 db_Sell_Margin, float64 myOrderBuyMinimum, float64 myOrderSellMinimum)
{
	variable int i = 1
	variable index:item HangarItems
	variable index:item HangarShips

	variable iterator HangarIterator

	variable int HangarShipsCount
	variable int HangarItemsCount

	Me.Station:GetHangarShips[HangarShips,"db_TypeID"]
	Me.Station:GetHangarItems[HangarItems,"db_TypeID"]

	HangarItemsCount:Set[${HangarItems.Used}]
	HangarShipsCount:Set[${HangarShips.Used}]

	if ${db_SellOrderQuan} == 0
	{
		echo Sell order quantity says not to sell anything, not selling anything!
		return
	}

	HangarItems:GetIterator[HangarIterator]

	do
	{
		if (${HangarIterator.Value.TypeID} == ${db_TypeID})
		{
			if (${HangarIterator.Value.Quantity} >= ${db_SellOrderQuan})
			{
				if (${db_Stock} != 0) && (${db_Stock} > 0)
				{
					call putInSellOrder ${db_TypeID} ${db_SellOrderQuan} ${db_Stock} ${myBuyID} ${mySellID} ${db_Sell_Margin} ${myOrderBuyMinimum} ${myOrderSellMinimum}
					return
				}
				if (${db_Stock} == 0)
				{
					echo Liquidating: ${HangarIterator.Value.Quantity} : ${HangarItems.Value.Name} (s)
					call putInSellOrder ${db_TypeID} ${HangarIterator.Value.Quantity} ${db_Stock} ${myBuyID} ${mySellID} ${db_Sell_Margin} ${myOrderBuyMinimum} ${myOrderSellMinimum}
					return
				}
				if ${db_Stock} < 0
				{
					echo Error! XML error db_Stock is set to less than zero!
					return
				}
			}
		}
	}
	while ${HangarIterator:Next(exists)}

	i:Set[1]

	HangarShips:GetIterator[HangarIterator]

	do
	{
		if (${HangarIterator.Value.TypeID} == ${db_TypeID})
		{
			if (${HangarIterator.Value.Quantity} >= ${db_SellOrderQuan})
			{
				if (${db_Stock} != 0) && (${db_Stock} > 0)
				{
					call putInSellOrder ${db_TypeID} ${db_SellOrderQuan} ${db_Stock} ${myBuyID} ${mySellID} ${db_Sell_Margin} ${myOrderBuyMinimum} ${myOrderSellMinimum}
					return
				}
				if (${db_Stock} == 0)
				{
					echo Liquidating: ${HangarIterator.Value.Quantity} :  ${HangarItems.Value.Name} (s)
					call putInSellOrder ${db_TypeID} ${HangarIterator.Value.Quantity} ${db_Stock} ${myBuyID} ${mySellID} ${db_Sell_Margin} ${myOrderBuyMinimum} ${myOrderSellMinimum}
					return
				}
				if ${db_Stock} < 0
				{
					echo Error! XML error db_Stock is set to less than zero!
					return
				}
			}
		}
	}
	while ${HangarIterator:Next(exists)}
}

;****************************************************************************************************************************************************************************************************************************************************

function modOrderBuy(int db_TypeID, float64 priceOne, float64 priceTwo, float64 myPriceBuy)
{
	variable iterator OrderIterator
	variable index:myorder MyOrders
	variable int OrdersCount
	variable int i = 1
	variable float64 num = 0

	variable string SetName = ""
	variable settingsetref thisSet
	thisSet:Set[${LavishSettings[DataTrackerSettings].FindSet[${SetName}]}]
	variable filepath DATA_PATH = "${Script.CurrentDirectory}"
	variable string DATA_FILE = "Data_Tracker.xml"

	if ${priceOne} <= 10
	{
		echo Error Buy Price Too Low!
		Return
	}

	MyOrders:Clear

	EVE:ClearMarketOrderCache
	Me:UpdateMyOrders

	i:Set[1]

	do
	{
		Me:GetMyOrders[MyOrders]
		wait 10
		if ${i} > 5
		break
		i:Inc
	}
	while !${MyOrders.Used}

	i:Set[1]

	MyOrders:GetIterator[OrderIterator]

	if ${OrderIterator:First(exists)}
	do
	{
		if (${OrderIterator.Value.IsBuyOrder})
		{
			if (${OrderIterator.Value.TypeID} == ${db_TypeID})
			{
				SetName:Set["Modifies"]
				thisSet:Set[${LavishSettings[DataTrackerSettings].FindSet[${SetName}]}]
				variable int modifies
				modifies:Set[${Math.Calc[${thisSet.FindSetting[Modifications]} + 1]}]
				LavishSettings[DataTrackerSettings].FindSet[${SetName}]:AddSetting[Modifications,${modifies}]
				LavishSettings[DataTrackerSettings]:Export[${DATA_FILE}]
				echo Updating Modification Value, theres been ${modifies} modification(s)!
				num:Set[${Math.Calc[${priceOne} + ${priceTwo}]}]
				OrderIterator.Value:Modify[${num}]
				BuyOrdersTimeStamp:Set[${OrderIterator.Value.TypeID},${Time.Timestamp}]
				echo Updating The Price of (${OrderIterator.Value.Name}) from ${myPriceBuy} to ${num}
				wait ${Math.Rand[20]:Inc[50]}
				return
			}
		}
	}
	while ${OrderIterator:Next(exists)}
}

;****************************************************************************************************************************************************************************************************************************************************

function modOrderSell(int db_TypeID, float64 priceOne, float64 priceTwo, float64 myPriceSell)
{
	variable iterator OrderIterator
	variable index:myorder MyOrders
	variable int OrdersCount
	variable int i = 1
	variable float64 num = 0

	variable string SetName = ""
	variable settingsetref thisSet
	thisSet:Set[${LavishSettings[DataTrackerSettings].FindSet[${SetName}]}]
	variable filepath DATA_PATH = "${Script.CurrentDirectory}"
	variable string DATA_FILE = "Data_Tracker.xml"

	if ${priceOne} <= 10
	{
		echo Error Sell Price Too Low!
		Return
	}

	MyOrders:Clear

	EVE:ClearMarketOrderCache
	Me:UpdateMyOrders

	i:Set[1]

	do
	{
		Me:GetMyOrders[MyOrders]
		wait 10
		if ${i} > 5
		break
		i:Inc
	}
	while !${MyOrders.Used}

	i:Set[1]

	MyOrders:GetIterator[OrderIterator]

	if ${OrderIterator:First(exists)}
	do
	{
		if (${OrderIterator.Value.IsSellOrder})
		{
			if (${OrderIterator.Value.TypeID} == ${db_TypeID})
			{
				SetName:Set["Modifies"]
				thisSet:Set[${LavishSettings[DataTrackerSettings].FindSet[${SetName}]}]
				variable int modifies
				modifies:Set[${Math.Calc[${thisSet.FindSetting[Modifications]} + 1]}]
				LavishSettings[DataTrackerSettings].FindSet[${SetName}]:AddSetting[Modifications,${modifies}]
				LavishSettings[DataTrackerSettings]:Export[${DATA_FILE}]
				echo Updating Modification Value, theres been ${modifies} modification(s)!
				num:Set[${Math.Calc[${priceOne} - ${priceTwo}]}]
				OrderIterator.Value:Modify[${num}]
				SellOrdersTimeStamp:Set[${OrderIterator.Value.TypeID},${Time.Timestamp}]
				echo Updating The Price of (${OrderIterator.Value.Name}) from ${myPriceSell} to ${num}
				wait ${Math.Rand[20]:Inc[50]}
				return
			}
		}
	}
	while ${OrderIterator:Next(exists)}
}