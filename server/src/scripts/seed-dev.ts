import {
  encryptPersonalData,
  phoneLookupHash,
} from "../security/crypto";
import { env } from "../config";
import { pool } from "../db";

const developmentProfiles = [
  {
    phone: "+999000000101",
    firstName: "Kavin",
    lastInitial: "R",
    gender: "male",
    dob: "1995-04-12",
    education: "B.E. Computer Science",
    occupation: "Software Engineer",
    city: "Chennai",
    bio: "Fictional development profile. Enjoys Carnatic music and weekend treks.",
    verified: true,
  },
  {
    phone: "+999000000102",
    firstName: "Nila",
    lastInitial: "S",
    gender: "female",
    dob: "1997-09-08",
    education: "M.Sc. Mathematics",
    occupation: "Data Analyst",
    city: "Coimbatore",
    bio: "Fictional development profile. Values family time, books, and travel.",
    verified: true,
  },
  {
    phone: "+999000000103",
    firstName: "Arjun",
    lastInitial: "M",
    gender: "male",
    dob: "1992-01-23",
    education: "MBA",
    occupation: "Operations Manager",
    city: "Madurai",
    bio: "Fictional development profile. A food enthusiast who enjoys volunteering.",
    verified: false,
  },
  {
    phone: "+999000000104",
    firstName: "Yazhini",
    lastInitial: "K",
    gender: "female",
    dob: "1999-06-17",
    education: "B.E. Electronics",
    occupation: "Product Designer",
    city: "Tiruchirappalli",
    bio: "Fictional development profile. Loves design, classical dance, and nature.",
    verified: false,
  },
  {
    phone: "+999000000105",
    firstName: "Pranav",
    lastInitial: "V",
    gender: "male",
    dob: "1989-11-02",
    education: "M.Com",
    occupation: "Chartered Accountant",
    city: "Salem",
    bio: "Fictional development profile. Close to family and enjoys cricket.",
    verified: true,
  },
  {
    phone: "+999000000106",
    firstName: "Mithra",
    lastInitial: "P",
    gender: "female",
    dob: "1994-02-27",
    education: "MBBS",
    occupation: "Doctor",
    city: "Tirunelveli",
    bio: "Fictional development profile. Finds joy in healthcare and gardening.",
    verified: true,
  },
  {
    phone: "+999000000107",
    firstName: "Sanjay",
    lastInitial: "D",
    gender: "male",
    dob: "1998-12-05",
    education: "B.Tech. Mechanical Engineering",
    occupation: "Design Engineer",
    city: "Erode",
    bio: "Fictional development profile. Enjoys photography and exploring Tamil Nadu.",
    verified: false,
  },
  {
    phone: "+999000000108",
    firstName: "Kayal",
    lastInitial: "A",
    gender: "female",
    dob: "1991-07-19",
    education: "M.A. Tamil",
    occupation: "Lecturer",
    city: "Thanjavur",
    bio: "Fictional development profile. Interested in Tamil literature and heritage.",
    verified: true,
  },
] as const;

async function seedDevelopmentProfiles(): Promise<void> {
  if (env.NODE_ENV !== "development") {
    throw new Error("Development seed data can only be loaded when NODE_ENV=development.");
  }

  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    for (const profile of developmentProfiles) {
      const phoneHash = phoneLookupHash(profile.phone);
      const user = await client.query(
        `INSERT INTO users (
           phone_e164_encrypted, phone_lookup_hash, gender, date_of_birth,
           created_for, account_status, phone_verified_at, verified_badge
         )
         VALUES ($1, $2, $3, $4, 'self', 'active', now(), $5)
         ON CONFLICT (phone_lookup_hash) DO UPDATE
           SET updated_at = now()
         RETURNING id`,
        [
          encryptPersonalData(profile.phone),
          phoneHash,
          profile.gender,
          profile.dob,
          profile.verified,
        ],
      );
      const userId = user.rows[0].id as string;
      await client.query(
        `INSERT INTO profiles (
           user_id, display_first_name, display_last_initial,
           full_name_encrypted, marital_status, education, occupation,
           city, state, country_code, bio
         )
         VALUES ($1, $2, $3, $4, 'never_married', $5, $6, $7, 'Tamil Nadu', 'IN', $8)
         ON CONFLICT (user_id) DO UPDATE SET
           display_first_name = EXCLUDED.display_first_name,
           display_last_initial = EXCLUDED.display_last_initial,
           full_name_encrypted = EXCLUDED.full_name_encrypted,
           education = EXCLUDED.education,
           occupation = EXCLUDED.occupation,
           city = EXCLUDED.city,
           state = EXCLUDED.state,
           bio = EXCLUDED.bio,
           updated_at = now()`,
        [
          userId,
          profile.firstName,
          profile.lastInitial,
          encryptPersonalData(`${profile.firstName} ${profile.lastInitial}`),
          profile.education,
          profile.occupation,
          profile.city,
          profile.bio,
        ],
      );
    }
    await client.query("COMMIT");
    console.info(`Seeded ${developmentProfiles.length} fictional development profiles.`);
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

void seedDevelopmentProfiles().catch((error: unknown) => {
  console.error("Development profile seeding failed.", error);
  process.exitCode = 1;
});
