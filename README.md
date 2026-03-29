RCB IPL Strategy Analysis (2013–2016)
A high-performance SQL portfolio project transforming 4 seasons of ball-by-ball IPL data into actionable squad-building intelligence. This project identifies why high-scoring teams fail to win titles and prescribes a data-backed "Mega-Auction" roadmap.

Live Demo: https://rcbstragy.netlify.app/

🏏 Project Overview
Using a relational database of 255 matches and 60,000+ deliveries, this analysis investigates the "Trophy Drought" of Royal Challengers Bangalore (RCB). By querying player performance, venue bias, and toss impact, the project builds a structural blueprint for a winning franchise.

Data at a Glance
Dataset: 4 Seasons (2013–2016)

Granularity: 60,223 Ball-by-ball records

Scope: 469 Players across 20 relational tables

Success Metric: Strike Rate vs. Volume duality and Bowling Efficiency

🛠️ Technical Stack & SQL Techniques
Database: MySQL Workbench

Advanced Querying: * CTEs & Subqueries: For multi-stage data transformation.

Window Functions: RANK(), LAG(), and OVER(PARTITION BY) for year-on-year trends.

Complex JOINs: Linking 5+ tables (Matches, Players, Ball-by-Ball, Wickets, Venues).

Aggregation & Logic: CASE WHEN, COALESCE, and STDDEV for player consistency.

Visualization: Chart.js, HTML5, CSS3 (Netlify Deployment).

📊 Key Strategic Findings
The "Trophy Drought" Pattern: RCB’s total runs increased annually (2,460 → 2,859), but total wickets fell (78 → 71). The 2016 Final loss was a bowling collapse, not a batting failure.

The Dual-Threat Elite: AB de Villiers was the only player in the top 5 for both Strike Rate (164.27) and Seasonal Average (492 runs).

Toss Advantage: Fielding first yields a 54.97% win rate compared to 42.86% when batting first—a 12% mathematical edge.

Venue Intelligence: David Warner averages 52.00 at Chinnaswamy (35% above his career average), proving that venue-specific signings provide "free" performance gains.

🚀 The Mega-Auction Roadmap
The analysis concludes with a 4-point priority plan for the RCB front office:

Retain Dual-Threat Assets: Secure players like ABD who minimize batting risk.

Prioritize Death Overs: Target bowlers with sub-8.5 economy in overs 17–20.

Spin Efficiency: Invest in Legbreak-Googly bowlers (highest wickets/match at 1.85).

Venue Specialists: Sign "Home Ground" specialists to maximize win probability at zero extra cost.

📁 Repository Structure
/sql_queries: Contains the 15+ logical queries used for extraction.

/data: Schema information and table relationships.

/web_assets: Frontend code for the interactive dashboard.

Developed by Adithya Patel Data Analyst | Hyderabad, India Specializing in SQL, Business Intelligence, and Sports Analytics.
