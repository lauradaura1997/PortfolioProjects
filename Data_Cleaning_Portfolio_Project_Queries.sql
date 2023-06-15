/*

Cleaning Data in SQL Queries. My own notes from the Alex the Analyst
Data Cleaning in SQL Tutorial on Youtube. Full permission from him to
reuse code for learning purposes.

*/

-- 1. First view all data.


Select *
From PortfolioProject.dbo.NashvilleHousing
--------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format
-- Select SaleDate, CONVERT(Date,SaleData)
-- From PortfolioProject.dbo.NashvilleHousing -- Didn't work -- we'll 
-- figure it out another time didn't work in video either.

Update PortfolioProject.dbo.NashvilleHousing
SET SaleDate = CONVERT(Date,SaleDate)

-- OR do it with ALTER function:

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
Add SaleDateConverted Date; 

Update PortfolioProject.dbo.NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)

-- Worked let's view it.
Select saleDateConverted, CONVERT(Date,SaleDate)
From PortfolioProject.dbo.NashvilleHousing

-- Great work team -- might remove SaleDate column at end
-- and just have new column.



Select saleDateConverted, CONVERT(Date,SaleDate)
From PortfolioProject.dbo.NashvilleHousing


Update NashvilleHousing
SET SaleDate = CONVERT(Date,SaleDate)

-- If it doesn't Update properly

ALTER TABLE NashvilleHousing
Add SaleDateConverted Date;

Update NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)


 --------------------------------------------------------------------------------------------------------------------------



-- 2. Populate Property Address data
--First let's just look at it.

Select *
From PortfolioProject.dbo.NashvilleHousing
Where PropertyAddress is null

-- We'll see there are NULL values when we run this.

-- Let's do some experimenting. So if we look at ParcelID for example, we'll see
-- cases of the same ID and same property address.

Select *
From PortfolioProject.dbo.NashvilleHousing

--Where PropertyAddress is null

order by ParcelID

-- We see we have parcel ID, sale price, etc. We also have property
-- address which isn't going to change. Therefore the property address
-- could be populated if we had a reference point to base it off. When 
-- displaying property address, we can see parcelID always has same property
-- address where it occurs more than once. We can therefore populate PropertyAddress
-- with parcelID. So let's do that.


Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
From PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null


Update a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
From PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null

-- Now display it

Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
From PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]


Select PropertyAddress
From PortfolioProject.dbo.NashvilleHousing

--Where PropertyAddress is null
--order by ParcelID
--------------------------------------------------------------------------------------------------------------------------



-- 3. Breaking out Address into Individual Columns (Address, City, State).

-- We can see the
-- only commas in the whole table are in the property address. We will use a substring and
-- character index.
-- So substring, property address, and we want to look at position one. The next part will 
-- show what the character index is looking for -- the specific value "," we're looking for. 
-- Can be word or anything. And also include where we're looking for it in parenthesis. So
-- until now, it's taking propertyaddress, going from the first value and going until the comma.
-- But you don't want a comma at the end of every address so we add "-1" so we go to the comma
-- and then one back from it. 
--For the second substring, we need to specify where we want it to begin -- so go to the comma 
-- and then go one beyond that. Then the length of property address.

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress)) as Address
From PortfolioProject.dbo.NashvilleHousing

-- This works well for separating the town from the street name/number. If we take out the +1, 
-- the comma will be included in the town.
-- So let's add these two separated columns to the table now.

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
Add PropertySplitAddress Nvarchar(255);

Update PortfolioProject.dbo.NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )

-- The town column too:

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
Add PropertySplitCity Nvarchar(255);

Update PortfolioProject.dbo.NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress))


-- And finally, display whole table again with two new columns. Using
-- the address column as it was was going to be tricky and cause problems.

Select *
From PortfolioProject.dbo.NashvilleHousing





-- 4. Now we'll look at owneraddress, for which we haveaddress, we have address, city, and state.


Select OwnerAddress
From PortfolioProject.dbo.NashvilleHousing

-- Theres another way to split which is more 
-- complex but actually simpler. For owner address, we have address, city, and state
-- and want to split them out.
-- Don't want to use painful substrings again... can alternatively use parsename which 
-- is super useful for delimited things. But PARSENAME only works for "."s. So we 
-- specify that we want to replace the ","s with "."s in the function and then split it
-- out. PARSENAME then creates a table. But you have to specify the order of the 3 things
-- you've just split. Otherwise it'll put the state first... and therefore we put 3,2,1.

Select
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
From PortfolioProject.dbo.NashvilleHousing

-- So now we have owneraddress broken into address, city, and state. Easier than substring so
-- we'll use it more. Now we just need to add those columns and then the values.

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
Add OwnerSplitAddress Nvarchar(255);

Update PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)


ALTER TABLE PortfolioProject.dbo.NashvilleHousing
Add OwnerSplitCity Nvarchar(255);

Update PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)



ALTER TABLE PortfolioProject.dbo.NashvilleHousing
Add OwnerSplitState Nvarchar(255);

Update PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)



Select *
From PortfolioProject.dbo.NashvilleHousing




--------------------------------------------------------------------------------------------------------------------------


-- 5. Change Y and N to Yes and No in "Sold as Vacant" field


Select Distinct(SoldasVacant)
From PortfolioProject.dbo.NashvilleHousing

Select SoldAsVacant
, CASE When SoldAsVacant = '1' THEN 'YES'
When SoldAsVacant = '0' THEN 'NO'
ELSE SoldAsVacant
END 
From PortfolioProject.dbo.NashvilleHousing

 
Update PortfolioProject.dbo.NashvilleHousing
SET SoldAsVacant = CASE When SoldAsVacant = '1' THEN 'Yes'
	   When SoldAsVacant = '0' THEN 'No'
	   ELSE SoldAsVacant
	   END

Select *
From PortfolioProject.dbo.NashvilleHousing

-- Great work team!

-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- 6. Remove Duplicates. We are going to delete them here but it's not a standard 
-- practise to delete actual data in database. Just remember. We're going to use a CTE
-- Specifies a temporary named result set, known as a common table expression (CTE).
-- This is derived from a simple query and defined within the execution scope of a single
-- SELECT, INSERT, UPDATE, DELETE or MERGE statement. This clause can also be used 
-- in a CREATE VIEW statement as part of its defining SELECT statement.
-- We'll do some window functions to
--A window function performs a calculation across a set of table rows that are somehow
-- related to the current row. This is comparable to the type of calculation that can be
-- done with an aggregate function. But unlike regular aggregate functions, use of a window
-- function does not cause rows to become grouped into a single output row — the rows retain
-- their separate identities. Behind the scenes, the window function is able to access more
-- than just the current row of the query result.
-- We want to partition data. When removing duplicates, we'll have duplicate rows and need
-- to have way to identify rows. You can use thinks like rank, orderrank, rownumber. 
--Here we'll use rownumber *Have a look at how these work. Rownumber is relatively simple.

Select *
From PortfolioProject.dbo.NashvilleHousing


-- So use rownumber, parenthesis and then need to write what it will partition on. Need to partition
-- it on things that should be unique to each row. Going to pretend UniqueID isn't there as its always
-- different. But if things like propertyaddress, saleprice, saledate, legalreference the same, then 
-- it looks like its the same data and unusable. So that's what we want to partition on and pretend
-- UniqueID doesn't exist. SaleDate an obvious one. Then we want to ORDERBY something that should be 
-- unique. So the UniqueID. And close it off. Then we'll call it rownum. And need to go back to the top 
-- and put it in a CTE called RowNumCTE and close brackets. Next query therefore queries off the temptable
-- RowNumCTE we created.

WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

From PortfolioProject.dbo.NashvilleHousing

--order by ParcelID
)

-- Now we want to select all values where rownum greater than 1 because rownum now a row. 

SELECT *
From RowNumCTE
Where row_num > 1
Order by PropertyAddress
-- And we get duplicates. We have 104 duplicates which we want to delete so we simply change
-- the SELECT above to DELETE. And then change it back to SELECT and we see there are none now.

Select *
From PortfolioProject.dbo.NashvilleHousing




---------------------------------------------------------------------------------------------------------

-- 7. Delete Unused Columns
-- Now we're just going to delete any columns we won't use. Note: don't do this on raw data
-- only at the end when you're not going to use them for analysis. OwnerAddress not as usable as
-- OwnerSplitAddress so we'll drop it. Also the Taxdistrict we can't use or the PropertyAddress.
-- Also saledate we don't need because we have saledateconverted.

Select *
From PortfolioProject.dbo.NashvilleHousing


ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

-- And then all of them are gone. 
-- Whole point was to clean data and make it usable for analysis. 
-- So quick recap: 1. Tried to standardise date format using convert.
-- 2. Populated the propertyaddress, which we did BEFORE breaking address
-- out into individual columns (address, city, state) -- we deleted propertyaddress
-- after so needed to do it in that order otherwise we would have lost all that data.
-- So we broke it out using substring charindex and parsename and replace. Then we converted
-- 1s and 0s to Yes and Nos using case statements. Then we removed duplicates using rownumber
-- a CTE and a windows function of partitionby. And then we just deleted useless columns we wouldn't 
-- need for the analysis.














-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

--- Importing Data using OPENROWSET and BULK INSERT	

--  More advanced and looks cooler, but have to configure server appropriately to do correctly
--  Wanted to provide this in case you wanted to try it


--sp_configure 'show advanced options', 1;
--RECONFIGURE;
--GO
--sp_configure 'Ad Hoc Distributed Queries', 1;
--RECONFIGURE;
--GO


--USE PortfolioProject 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1 

--GO 


---- Using BULK INSERT

--USE PortfolioProject;
--GO
--BULK INSERT nashvilleHousing FROM 'C:\Temp\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv'
--   WITH (
--      FIELDTERMINATOR = ',',
--      ROWTERMINATOR = '\n'
--);
--GO


---- Using OPENROWSET
--USE PortfolioProject;
--GO
--SELECT * INTO nashvilleHousing
--FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
--    'Excel 12.0; Database=C:\Users\alexf\OneDrive\Documents\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv', [Sheet1$]);
--GO


















